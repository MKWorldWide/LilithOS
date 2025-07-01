/*
 * LilithOS Network Bridge
 * Netgear Nighthawk R7000P Router Integration
 * 
 * This module provides network bridge functionality for LilithOS integration
 * with the Nintendo Switch development environment.
 *
 * Author: LilithOS Development Team
 * Version: 1.0.0
 * License: GPL v2
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/netdevice.h>
#include <linux/skbuff.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <linux/inetdevice.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/sysfs.h>
#include <linux/kobject.h>
#include <linux/workqueue.h>
#include <linux/timer.h>
#include <linux/jiffies.h>
#include <linux/string.h>
#include <linux/slab.h>
#include <linux/random.h>
#include <linux/crypto.h>
#include <linux/scatterlist.h>

#define LILITHOS_BRIDGE_VERSION "1.0.0"
#define LILITHOS_BRIDGE_NAME "lilithos_bridge"
#define LILITHOS_SWITCH_PORT 8080
#define LILITHOS_HEARTBEAT_INTERVAL (5 * HZ)  // 5 seconds
#define LILITHOS_MAX_CONNECTIONS 100
#define LILITHOS_ENCRYPTION_KEY_SIZE 32

// LilithOS Bridge structure
struct lilithos_bridge {
    struct net_device *dev;
    struct timer_list heartbeat_timer;
    struct work_struct heartbeat_work;
    spinlock_t lock;
    atomic_t connection_count;
    struct list_head connections;
    u8 encryption_key[LILITHOS_ENCRYPTION_KEY_SIZE];
    bool bridge_active;
    u32 switch_ip;
    u16 switch_port;
    struct proc_dir_entry *proc_entry;
    struct kobject *kobj;
};

// Connection tracking structure
struct lilithos_connection {
    struct list_head list;
    u32 src_ip;
    u32 dst_ip;
    u16 src_port;
    u16 dst_port;
    u8 protocol;
    u64 bytes_sent;
    u64 bytes_received;
    unsigned long last_seen;
    bool encrypted;
    u8 session_key[LILITHOS_ENCRYPTION_KEY_SIZE];
};

static struct lilithos_bridge *lilithos_bridge = NULL;

// ============================================================================
// ENCRYPTION FUNCTIONS
// ============================================================================

static int lilithos_encrypt_data(const u8 *key, const u8 *data, size_t data_len, 
                                u8 *encrypted, size_t *encrypted_len) {
    struct crypto_cipher *cipher;
    struct scatterlist sg;
    int ret = 0;
    
    cipher = crypto_alloc_cipher("aes", 0, 0);
    if (IS_ERR(cipher)) {
        return PTR_ERR(cipher);
    }
    
    ret = crypto_cipher_setkey(cipher, key, LILITHOS_ENCRYPTION_KEY_SIZE);
    if (ret) {
        goto out;
    }
    
    sg_init_one(&sg, (void *)data, data_len);
    crypto_cipher_encrypt_one(cipher, encrypted, data);
    *encrypted_len = data_len;
    
out:
    crypto_free_cipher(cipher);
    return ret;
}

static int lilithos_decrypt_data(const u8 *key, const u8 *encrypted, size_t encrypted_len,
                                u8 *decrypted, size_t *decrypted_len) {
    struct crypto_cipher *cipher;
    struct scatterlist sg;
    int ret = 0;
    
    cipher = crypto_alloc_cipher("aes", 0, 0);
    if (IS_ERR(cipher)) {
        return PTR_ERR(cipher);
    }
    
    ret = crypto_cipher_setkey(cipher, key, LILITHOS_ENCRYPTION_KEY_SIZE);
    if (ret) {
        goto out;
    }
    
    sg_init_one(&sg, (void *)encrypted, encrypted_len);
    crypto_cipher_decrypt_one(cipher, decrypted, encrypted);
    *decrypted_len = encrypted_len;
    
out:
    crypto_free_cipher(cipher);
    return ret;
}

// ============================================================================
// NETWORK PACKET PROCESSING
// ============================================================================

static unsigned int lilithos_nf_hook(void *priv, struct sk_buff *skb,
                                   const struct nf_hook_state *state) {
    struct iphdr *iph;
    struct tcphdr *tcph;
    struct udphdr *udph;
    struct lilithos_connection *conn;
    unsigned long flags;
    
    if (!skb || !lilithos_bridge || !lilithos_bridge->bridge_active) {
        return NF_ACCEPT;
    }
    
    iph = ip_hdr(skb);
    if (!iph) {
        return NF_ACCEPT;
    }
    
    // Check if packet is from/to Switch
    if (iph->saddr == lilithos_bridge->switch_ip || 
        iph->daddr == lilithos_bridge->switch_ip) {
        
        spin_lock_irqsave(&lilithos_bridge->lock, flags);
        
        // Find or create connection
        list_for_each_entry(conn, &lilithos_bridge->connections, list) {
            if (conn->src_ip == iph->saddr && conn->dst_ip == iph->daddr) {
                if (iph->protocol == IPPROTO_TCP) {
                    tcph = tcp_hdr(skb);
                    if (conn->src_port == tcph->source && conn->dst_port == tcph->dest) {
                        conn->last_seen = jiffies;
                        conn->bytes_received += skb->len;
                        break;
                    }
                } else if (iph->protocol == IPPROTO_UDP) {
                    udph = udp_hdr(skb);
                    if (conn->src_port == udph->source && conn->dst_port == udph->dest) {
                        conn->last_seen = jiffies;
                        conn->bytes_received += skb->len;
                        break;
                    }
                }
            }
        }
        
        // Create new connection if not found
        if (&conn->list == &lilithos_bridge->connections) {
            if (atomic_read(&lilithos_bridge->connection_count) < LILITHOS_MAX_CONNECTIONS) {
                conn = kzalloc(sizeof(*conn), GFP_ATOMIC);
                if (conn) {
                    conn->src_ip = iph->saddr;
                    conn->dst_ip = iph->daddr;
                    conn->protocol = iph->protocol;
                    conn->last_seen = jiffies;
                    conn->bytes_received = skb->len;
                    
                    if (iph->protocol == IPPROTO_TCP) {
                        tcph = tcp_hdr(skb);
                        conn->src_port = tcph->source;
                        conn->dst_port = tcph->dest;
                    } else if (iph->protocol == IPPROTO_UDP) {
                        udph = udp_hdr(skb);
                        conn->src_port = udph->source;
                        conn->dst_port = udph->dest;
                    }
                    
                    // Generate session key
                    get_random_bytes(conn->session_key, LILITHOS_ENCRYPTION_KEY_SIZE);
                    conn->encrypted = true;
                    
                    list_add(&conn->list, &lilithos_bridge->connections);
                    atomic_inc(&lilithos_bridge->connection_count);
                }
            }
        }
        
        spin_unlock_irqrestore(&lilithos_bridge->lock, flags);
    }
    
    return NF_ACCEPT;
}

static struct nf_hook_ops lilithos_nf_ops = {
    .hook = lilithos_nf_hook,
    .pf = NFPROTO_IPV4,
    .hooknum = NF_INET_PRE_ROUTING,
    .priority = NF_IP_PRI_FIRST,
};

// ============================================================================
// HEARTBEAT AND MONITORING
// ============================================================================

static void lilithos_heartbeat_work(struct work_struct *work) {
    struct lilithos_bridge *bridge = container_of(work, struct lilithos_bridge, heartbeat_work);
    struct lilithos_connection *conn, *tmp;
    unsigned long flags;
    unsigned long timeout = jiffies - (30 * HZ); // 30 second timeout
    
    spin_lock_irqsave(&bridge->lock, flags);
    
    // Clean up stale connections
    list_for_each_entry_safe(conn, tmp, &bridge->connections, list) {
        if (time_after(timeout, conn->last_seen)) {
            list_del(&conn->list);
            kfree(conn);
            atomic_dec(&bridge->connection_count);
        }
    }
    
    spin_unlock_irqrestore(&bridge->lock, flags);
    
    // Schedule next heartbeat
    mod_timer(&bridge->heartbeat_timer, jiffies + LILITHOS_HEARTBEAT_INTERVAL);
}

static void lilithos_heartbeat_timer(struct timer_list *t) {
    struct lilithos_bridge *bridge = from_timer(bridge, t, heartbeat_timer);
    schedule_work(&bridge->heartbeat_work);
}

// ============================================================================
// PROC FILESYSTEM INTERFACE
// ============================================================================

static int lilithos_proc_show(struct seq_file *m, void *v) {
    struct lilithos_connection *conn;
    unsigned long flags;
    
    seq_printf(m, "LilithOS Bridge Status\n");
    seq_printf(m, "=====================\n");
    seq_printf(m, "Version: %s\n", LILITHOS_BRIDGE_VERSION);
    seq_printf(m, "Bridge Active: %s\n", lilithos_bridge->bridge_active ? "Yes" : "No");
    seq_printf(m, "Switch IP: %pI4\n", &lilithos_bridge->switch_ip);
    seq_printf(m, "Switch Port: %d\n", lilithos_bridge->switch_port);
    seq_printf(m, "Active Connections: %d\n", atomic_read(&lilithos_bridge->connection_count));
    seq_printf(m, "\n");
    
    seq_printf(m, "Active Connections:\n");
    seq_printf(m, "%-15s %-15s %-8s %-8s %-8s %-12s %-12s\n",
               "Source IP", "Dest IP", "Src Port", "Dest Port", "Protocol", "Bytes Sent", "Bytes Recv");
    seq_printf(m, "%-15s %-15s %-8s %-8s %-8s %-12s %-12s\n",
               "---------", "--------", "--------", "--------", "--------", "-----------", "-----------");
    
    spin_lock_irqsave(&lilithos_bridge->lock, flags);
    list_for_each_entry(conn, &lilithos_bridge->connections, list) {
        seq_printf(m, "%-15pI4 %-15pI4 %-8d %-8d %-8s %-12llu %-12llu\n",
                   &conn->src_ip, &conn->dst_ip, ntohs(conn->src_port), 
                   ntohs(conn->dst_port),
                   conn->protocol == IPPROTO_TCP ? "TCP" : "UDP",
                   conn->bytes_sent, conn->bytes_received);
    }
    spin_unlock_irqrestore(&lilithos_bridge->lock, flags);
    
    return 0;
}

static int lilithos_proc_open(struct inode *inode, struct file *file) {
    return single_open(file, lilithos_proc_show, NULL);
}

static const struct proc_ops lilithos_proc_ops = {
    .proc_open = lilithos_proc_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

// ============================================================================
// SYSFS INTERFACE
// ============================================================================

static ssize_t lilithos_bridge_active_show(struct kobject *kobj, 
                                          struct kobj_attribute *attr, char *buf) {
    return sprintf(buf, "%d\n", lilithos_bridge->bridge_active ? 1 : 0);
}

static ssize_t lilithos_bridge_active_store(struct kobject *kobj,
                                           struct kobj_attribute *attr,
                                           const char *buf, size_t count) {
    int val;
    
    if (kstrtoint(buf, 10, &val)) {
        return -EINVAL;
    }
    
    lilithos_bridge->bridge_active = val ? true : false;
    return count;
}

static ssize_t lilithos_switch_ip_show(struct kobject *kobj,
                                      struct kobj_attribute *attr, char *buf) {
    return sprintf(buf, "%pI4\n", &lilithos_bridge->switch_ip);
}

static ssize_t lilithos_switch_ip_store(struct kobject *kobj,
                                       struct kobj_attribute *attr,
                                       const char *buf, size_t count) {
    if (in4_pton(buf, count, (u8 *)&lilithos_bridge->switch_ip, '\0', NULL)) {
        return count;
    }
    return -EINVAL;
}

static struct kobj_attribute lilithos_bridge_active_attr = 
    __ATTR(bridge_active, 0644, lilithos_bridge_active_show, lilithos_bridge_active_store);

static struct kobj_attribute lilithos_switch_ip_attr =
    __ATTR(switch_ip, 0644, lilithos_switch_ip_show, lilithos_switch_ip_store);

static struct attribute *lilithos_attrs[] = {
    &lilithos_bridge_active_attr.attr,
    &lilithos_switch_ip_attr.attr,
    NULL,
};

static struct attribute_group lilithos_attr_group = {
    .attrs = lilithos_attrs,
};

// ============================================================================
// MODULE INITIALIZATION AND CLEANUP
// ============================================================================

static int __init lilithos_bridge_init(void) {
    int ret;
    
    // Allocate bridge structure
    lilithos_bridge = kzalloc(sizeof(*lilithos_bridge), GFP_KERNEL);
    if (!lilithos_bridge) {
        return -ENOMEM;
    }
    
    // Initialize bridge
    spin_lock_init(&lilithos_bridge->lock);
    INIT_LIST_HEAD(&lilithos_bridge->connections);
    atomic_set(&lilithos_bridge->connection_count, 0);
    
    // Generate encryption key
    get_random_bytes(lilithos_bridge->encryption_key, LILITHOS_ENCRYPTION_KEY_SIZE);
    
    // Set default Switch IP (will be configured via sysfs)
    lilithos_bridge->switch_ip = in_aton("192.168.1.100");
    lilithos_bridge->switch_port = LILITHOS_SWITCH_PORT;
    lilithos_bridge->bridge_active = true;
    
    // Initialize heartbeat timer
    timer_setup(&lilithos_bridge->heartbeat_timer, lilithos_heartbeat_timer, 0);
    INIT_WORK(&lilithos_bridge->heartbeat_work, lilithos_heartbeat_work);
    mod_timer(&lilithos_bridge->heartbeat_timer, jiffies + LILITHOS_HEARTBEAT_INTERVAL);
    
    // Register netfilter hook
    ret = nf_register_net_hook(&init_net, &lilithos_nf_ops);
    if (ret) {
        pr_err("Failed to register netfilter hook: %d\n", ret);
        goto error_cleanup;
    }
    
    // Create proc entry
    lilithos_bridge->proc_entry = proc_create(LILITHOS_BRIDGE_NAME, 0444, NULL, &lilithos_proc_ops);
    if (!lilithos_bridge->proc_entry) {
        pr_err("Failed to create proc entry\n");
        goto error_unregister_hook;
    }
    
    // Create sysfs interface
    lilithos_bridge->kobj = kobject_create_and_add(LILITHOS_BRIDGE_NAME, kernel_kobj);
    if (!lilithos_bridge->kobj) {
        pr_err("Failed to create sysfs kobject\n");
        goto error_remove_proc;
    }
    
    ret = sysfs_create_group(lilithos_bridge->kobj, &lilithos_attr_group);
    if (ret) {
        pr_err("Failed to create sysfs attributes: %d\n", ret);
        goto error_remove_kobj;
    }
    
    pr_info("LilithOS Bridge initialized successfully (version %s)\n", LILITHOS_BRIDGE_VERSION);
    return 0;
    
error_remove_kobj:
    kobject_put(lilithos_bridge->kobj);
error_remove_proc:
    proc_remove(lilithos_bridge->proc_entry);
error_unregister_hook:
    nf_unregister_net_hook(&init_net, &lilithos_nf_ops);
error_cleanup:
    del_timer_sync(&lilithos_bridge->heartbeat_timer);
    cancel_work_sync(&lilithos_bridge->heartbeat_work);
    kfree(lilithos_bridge);
    lilithos_bridge = NULL;
    return ret;
}

static void __exit lilithos_bridge_exit(void) {
    struct lilithos_connection *conn, *tmp;
    unsigned long flags;
    
    if (!lilithos_bridge) {
        return;
    }
    
    // Stop heartbeat
    del_timer_sync(&lilithos_bridge->heartbeat_timer);
    cancel_work_sync(&lilithos_bridge->heartbeat_work);
    
    // Clean up connections
    spin_lock_irqsave(&lilithos_bridge->lock, flags);
    list_for_each_entry_safe(conn, tmp, &lilithos_bridge->connections, list) {
        list_del(&conn->list);
        kfree(conn);
    }
    spin_unlock_irqrestore(&lilithos_bridge->lock, flags);
    
    // Remove sysfs interface
    sysfs_remove_group(lilithos_bridge->kobj, &lilithos_attr_group);
    kobject_put(lilithos_bridge->kobj);
    
    // Remove proc entry
    proc_remove(lilithos_bridge->proc_entry);
    
    // Unregister netfilter hook
    nf_unregister_net_hook(&init_net, &lilithos_nf_ops);
    
    // Free bridge structure
    kfree(lilithos_bridge);
    lilithos_bridge = NULL;
    
    pr_info("LilithOS Bridge unloaded\n");
}

module_init(lilithos_bridge_init);
module_exit(lilithos_bridge_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("LilithOS Development Team");
MODULE_DESCRIPTION("LilithOS Network Bridge for Netgear Nighthawk R7000P");
MODULE_VERSION(LILITHOS_BRIDGE_VERSION); 