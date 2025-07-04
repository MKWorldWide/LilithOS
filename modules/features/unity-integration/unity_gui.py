#!/usr/bin/env python3
"""
Unity GUI Integration for LilithOS
Advanced visual controls and lifelike rendering interface
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional
import threading
import subprocess

from unity_visual_engine import UnityVisualEngine, LifelikeVisualRenderer

class UnityIntegrationGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("LilithOS Unity Visual Engine")
        self.root.geometry("1200x800")
        self.root.configure(bg='#1a1a1a')
        
        # Initialize Unity engine
        self.unity_engine = UnityVisualEngine()
        self.renderer = LifelikeVisualRenderer()
        
        # Current project state
        self.current_project = None
        self.current_scene = None
        
        self.setup_styles()
        self.create_widgets()
        self.load_unity_status()
    
    def setup_styles(self):
        """Configure modern dark theme styles"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Configure colors
        style.configure('TFrame', background='#1a1a1a')
        style.configure('TLabel', background='#1a1a1a', foreground='#ffffff')
        style.configure('TButton', background='#2d2d2d', foreground='#ffffff')
        style.configure('Header.TLabel', font=('Arial', 16, 'bold'))
        style.configure('Status.TLabel', font=('Arial', 10))
        
        # Notebook style
        style.configure('TNotebook', background='#1a1a1a')
        style.configure('TNotebook.Tab', background='#2d2d2d', foreground='#ffffff')
        style.map('TNotebook.Tab', background=[('selected', '#4a4a4a')])
    
    def create_widgets(self):
        """Create the main GUI layout"""
        # Main container
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Header
        header_frame = ttk.Frame(main_frame)
        header_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(header_frame, text="Unity Visual Engine", style='Header.TLabel').pack(side=tk.LEFT)
        
        # Status bar
        self.status_label = ttk.Label(header_frame, text="Initializing...", style='Status.TLabel')
        self.status_label.pack(side=tk.RIGHT)
        
        # Notebook for tabs
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        # Create tabs
        self.create_project_tab()
        self.create_visual_settings_tab()
        self.create_scene_editor_tab()
        self.create_rendering_tab()
        self.create_materials_tab()
        self.create_lighting_tab()
        self.create_post_processing_tab()
        self.create_export_tab()
    
    def create_project_tab(self):
        """Create project management tab"""
        project_frame = ttk.Frame(self.notebook)
        self.notebook.add(project_frame, text="Project")
        
        # Project info
        info_frame = ttk.LabelFrame(project_frame, text="Project Information", padding=10)
        info_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Project name
        ttk.Label(info_frame, text="Project Name:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.project_name_var = tk.StringVar(value="LilithOS_Visual_Project")
        ttk.Entry(info_frame, textvariable=self.project_name_var, width=30).grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # Project path
        ttk.Label(info_frame, text="Project Path:").grid(row=1, column=0, sticky=tk.W, pady=5)
        path_frame = ttk.Frame(info_frame)
        path_frame.grid(row=1, column=1, sticky=tk.W, pady=5)
        
        self.project_path_var = tk.StringVar(value="./unity_projects")
        ttk.Entry(path_frame, textvariable=self.project_path_var, width=40).pack(side=tk.LEFT)
        ttk.Button(path_frame, text="Browse", command=self.browse_project_path).pack(side=tk.LEFT, padx=(5, 0))
        
        # Unity version
        ttk.Label(info_frame, text="Unity Version:").grid(row=2, column=0, sticky=tk.W, pady=5)
        self.unity_version_var = tk.StringVar()
        self.unity_version_combo = ttk.Combobox(info_frame, textvariable=self.unity_version_var, state="readonly", width=20)
        self.unity_version_combo.grid(row=2, column=1, sticky=tk.W, pady=5)
        
        # Project actions
        actions_frame = ttk.LabelFrame(project_frame, text="Project Actions", padding=10)
        actions_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(actions_frame, text="Create New Project", command=self.create_project).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(actions_frame, text="Open Existing Project", command=self.open_project).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(actions_frame, text="Launch Unity", command=self.launch_unity).pack(side=tk.LEFT)
    
    def create_visual_settings_tab(self):
        """Create visual quality settings tab"""
        settings_frame = ttk.Frame(self.notebook)
        self.notebook.add(settings_frame, text="Visual Settings")
        
        # Quality presets
        presets_frame = ttk.LabelFrame(settings_frame, text="Quality Presets", padding=10)
        presets_frame.pack(fill=tk.X, padx=10, pady=10)
        
        self.quality_preset_var = tk.StringVar(value="Ultra")
        presets = ['Ultra', 'High', 'Medium', 'Low']
        
        for i, preset in enumerate(presets):
            ttk.Radiobutton(presets_frame, text=preset, variable=self.quality_preset_var, 
                           value=preset, command=self.apply_quality_preset).grid(row=0, column=i, padx=10)
        
        # Advanced settings
        advanced_frame = ttk.LabelFrame(settings_frame, text="Advanced Visual Settings", padding=10)
        advanced_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create scrollable frame
        canvas = tk.Canvas(advanced_frame, bg='#1a1a1a')
        scrollbar = ttk.Scrollbar(advanced_frame, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Visual settings variables
        self.ray_tracing_var = tk.BooleanVar(value=True)
        self.real_time_gi_var = tk.BooleanVar(value=True)
        self.volumetric_lighting_var = tk.BooleanVar(value=True)
        self.screen_space_reflections_var = tk.BooleanVar(value=True)
        self.ambient_occlusion_var = tk.BooleanVar(value=True)
        self.bloom_var = tk.BooleanVar(value=True)
        self.depth_of_field_var = tk.BooleanVar(value=True)
        self.motion_blur_var = tk.BooleanVar(value=True)
        self.vsync_var = tk.BooleanVar(value=True)
        
        # Anti-aliasing
        ttk.Label(scrollable_frame, text="Anti-Aliasing:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.anti_aliasing_var = tk.StringVar(value="TAA")
        anti_aliasing_combo = ttk.Combobox(scrollable_frame, textvariable=self.anti_aliasing_var, 
                                         values=["None", "FXAA", "TAA", "MSAA 2x", "MSAA 4x", "MSAA 8x"], 
                                         state="readonly", width=15)
        anti_aliasing_combo.grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # Shadow quality
        ttk.Label(scrollable_frame, text="Shadow Quality:").grid(row=1, column=0, sticky=tk.W, pady=5)
        self.shadow_quality_var = tk.StringVar(value="Ultra")
        shadow_quality_combo = ttk.Combobox(scrollable_frame, textvariable=self.shadow_quality_var,
                                          values=["Low", "Medium", "High", "Ultra"], state="readonly", width=15)
        shadow_quality_combo.grid(row=1, column=1, sticky=tk.W, pady=5)
        
        # Texture quality
        ttk.Label(scrollable_frame, text="Texture Quality:").grid(row=2, column=0, sticky=tk.W, pady=5)
        self.texture_quality_var = tk.StringVar(value="Ultra")
        texture_quality_combo = ttk.Combobox(scrollable_frame, textvariable=self.texture_quality_var,
                                           values=["Low", "Medium", "High", "Ultra"], state="readonly", width=15)
        texture_quality_combo.grid(row=2, column=1, sticky=tk.W, pady=5)
        
        # Frame rate target
        ttk.Label(scrollable_frame, text="Frame Rate Target:").grid(row=3, column=0, sticky=tk.W, pady=5)
        self.frame_rate_var = tk.IntVar(value=60)
        frame_rate_spinbox = ttk.Spinbox(scrollable_frame, from_=30, to=240, textvariable=self.frame_rate_var, width=10)
        frame_rate_spinbox.grid(row=3, column=1, sticky=tk.W, pady=5)
        
        # Checkboxes for advanced features
        row = 4
        ttk.Checkbutton(scrollable_frame, text="Ray Tracing", variable=self.ray_tracing_var).grid(row=row, column=0, sticky=tk.W, pady=2)
        ttk.Checkbutton(scrollable_frame, text="Real-Time Global Illumination", variable=self.real_time_gi_var).grid(row=row, column=1, sticky=tk.W, pady=2)
        
        row += 1
        ttk.Checkbutton(scrollable_frame, text="Volumetric Lighting", variable=self.volumetric_lighting_var).grid(row=row, column=0, sticky=tk.W, pady=2)
        ttk.Checkbutton(scrollable_frame, text="Screen Space Reflections", variable=self.screen_space_reflections_var).grid(row=row, column=1, sticky=tk.W, pady=2)
        
        row += 1
        ttk.Checkbutton(scrollable_frame, text="Ambient Occlusion", variable=self.ambient_occlusion_var).grid(row=row, column=0, sticky=tk.W, pady=2)
        ttk.Checkbutton(scrollable_frame, text="Bloom", variable=self.bloom_var).grid(row=row, column=1, sticky=tk.W, pady=2)
        
        row += 1
        ttk.Checkbutton(scrollable_frame, text="Depth of Field", variable=self.depth_of_field_var).grid(row=row, column=0, sticky=tk.W, pady=2)
        ttk.Checkbutton(scrollable_frame, text="Motion Blur", variable=self.motion_blur_var).grid(row=row, column=1, sticky=tk.W, pady=2)
        
        row += 1
        ttk.Checkbutton(scrollable_frame, text="VSync", variable=self.vsync_var).grid(row=row, column=0, sticky=tk.W, pady=2)
        
        # Pack canvas and scrollbar
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
    
    def create_scene_editor_tab(self):
        """Create scene editor tab"""
        scene_frame = ttk.Frame(self.notebook)
        self.notebook.add(scene_frame, text="Scene Editor")
        
        # Scene info
        scene_info_frame = ttk.LabelFrame(scene_frame, text="Scene Information", padding=10)
        scene_info_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(scene_info_frame, text="Scene Name:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.scene_name_var = tk.StringVar(value="LifelikeScene")
        ttk.Entry(scene_info_frame, textvariable=self.scene_name_var, width=30).grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # Scene actions
        scene_actions_frame = ttk.LabelFrame(scene_frame, text="Scene Actions", padding=10)
        scene_actions_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(scene_actions_frame, text="Create New Scene", command=self.create_scene).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(scene_actions_frame, text="Add Lighting", command=self.add_lighting).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(scene_actions_frame, text="Add Camera", command=self.add_camera).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(scene_actions_frame, text="Save Scene", command=self.save_scene).pack(side=tk.LEFT)
        
        # Scene hierarchy
        hierarchy_frame = ttk.LabelFrame(scene_frame, text="Scene Hierarchy", padding=10)
        hierarchy_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.scene_tree = ttk.Treeview(hierarchy_frame, columns=("Type", "Properties"), show="tree headings")
        self.scene_tree.heading("#0", text="Name")
        self.scene_tree.heading("Type", text="Type")
        self.scene_tree.heading("Properties", text="Properties")
        self.scene_tree.pack(fill=tk.BOTH, expand=True)
    
    def create_rendering_tab(self):
        """Create rendering settings tab"""
        render_frame = ttk.Frame(self.notebook)
        self.notebook.add(render_frame, text="Rendering")
        
        # Rendering pipeline
        pipeline_frame = ttk.LabelFrame(render_frame, text="Rendering Pipeline", padding=10)
        pipeline_frame.pack(fill=tk.X, padx=10, pady=10)
        
        self.pipeline_var = tk.StringVar(value="URP")
        ttk.Radiobutton(pipeline_frame, text="Built-in Render Pipeline", variable=self.pipeline_var, value="Built-in").pack(anchor=tk.W)
        ttk.Radiobutton(pipeline_frame, text="Universal Render Pipeline (URP)", variable=self.pipeline_var, value="URP").pack(anchor=tk.W)
        ttk.Radiobutton(pipeline_frame, text="High Definition Render Pipeline (HDRP)", variable=self.pipeline_var, value="HDRP").pack(anchor=tk.W)
        
        # Rendering settings
        render_settings_frame = ttk.LabelFrame(render_frame, text="Rendering Settings", padding=10)
        render_settings_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Resolution
        ttk.Label(render_settings_frame, text="Target Resolution:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.resolution_var = tk.StringVar(value="1920x1080")
        resolution_combo = ttk.Combobox(render_settings_frame, textvariable=self.resolution_var,
                                      values=["1280x720", "1920x1080", "2560x1440", "3840x2160"], state="readonly")
        resolution_combo.grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # HDR
        self.hdr_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(render_settings_frame, text="HDR", variable=self.hdr_var).grid(row=1, column=0, sticky=tk.W, pady=5)
        
        # MSAA
        ttk.Label(render_settings_frame, text="MSAA:").grid(row=2, column=0, sticky=tk.W, pady=5)
        self.msaa_var = tk.IntVar(value=4)
        msaa_spinbox = ttk.Spinbox(render_settings_frame, from_=0, to=8, textvariable=self.msaa_var, width=10)
        msaa_spinbox.grid(row=2, column=1, sticky=tk.W, pady=5)
    
    def create_materials_tab(self):
        """Create materials tab"""
        materials_frame = ttk.Frame(self.notebook)
        self.notebook.add(materials_frame, text="Materials")
        
        # Material library
        library_frame = ttk.LabelFrame(materials_frame, text="Material Library", padding=10)
        library_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Material list
        self.material_listbox = tk.Listbox(library_frame, bg='#2d2d2d', fg='#ffffff', selectmode=tk.SINGLE)
        self.material_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Material actions
        actions_frame = ttk.Frame(library_frame)
        actions_frame.pack(side=tk.RIGHT, fill=tk.Y, padx=(10, 0))
        
        ttk.Button(actions_frame, text="Create PBR Metal", command=lambda: self.create_material("PBR_Metal")).pack(pady=5)
        ttk.Button(actions_frame, text="Create PBR Plastic", command=lambda: self.create_material("PBR_Plastic")).pack(pady=5)
        ttk.Button(actions_frame, text="Create PBR Wood", command=lambda: self.create_material("PBR_Wood")).pack(pady=5)
        ttk.Button(actions_frame, text="Create PBR Glass", command=lambda: self.create_material("PBR_Glass")).pack(pady=5)
        ttk.Button(actions_frame, text="Create Custom Material", command=self.create_custom_material).pack(pady=5)
    
    def create_lighting_tab(self):
        """Create lighting tab"""
        lighting_frame = ttk.Frame(self.notebook)
        self.notebook.add(lighting_frame, text="Lighting")
        
        # Lighting setup
        setup_frame = ttk.LabelFrame(lighting_frame, text="Lighting Setup", padding=10)
        setup_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Environment lighting
        env_frame = ttk.LabelFrame(setup_frame, text="Environment Lighting", padding=10)
        env_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.ambient_lighting_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(env_frame, text="Enable Ambient Lighting", variable=self.ambient_lighting_var).pack(anchor=tk.W)
        
        ttk.Label(env_frame, text="Ambient Intensity:").pack(anchor=tk.W, pady=(10, 0))
        self.ambient_intensity_var = tk.DoubleVar(value=1.0)
        ambient_scale = ttk.Scale(env_frame, from_=0.0, to=2.0, variable=self.ambient_intensity_var, orient=tk.HORIZONTAL)
        ambient_scale.pack(fill=tk.X, pady=5)
        
        # Real-time lighting
        realtime_frame = ttk.LabelFrame(setup_frame, text="Real-Time Lighting", padding=10)
        realtime_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.realtime_gi_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(realtime_frame, text="Real-Time Global Illumination", variable=self.realtime_gi_var).pack(anchor=tk.W)
        
        ttk.Label(realtime_frame, text="GI Bounces:").pack(anchor=tk.W, pady=(10, 0))
        self.gi_bounces_var = tk.IntVar(value=2)
        gi_bounces_spinbox = ttk.Spinbox(realtime_frame, from_=1, to=4, textvariable=self.gi_bounces_var, width=10)
        gi_bounces_spinbox.pack(anchor=tk.W, pady=5)
        
        # Shadow settings
        shadow_frame = ttk.LabelFrame(setup_frame, text="Shadow Settings", padding=10)
        shadow_frame.pack(fill=tk.X)
        
        self.shadows_enabled_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(shadow_frame, text="Enable Shadows", variable=self.shadows_enabled_var).pack(anchor=tk.W)
        
        ttk.Label(shadow_frame, text="Shadow Distance:").pack(anchor=tk.W, pady=(10, 0))
        self.shadow_distance_var = tk.DoubleVar(value=150.0)
        shadow_distance_scale = ttk.Scale(shadow_frame, from_=50.0, to=500.0, variable=self.shadow_distance_var, orient=tk.HORIZONTAL)
        shadow_distance_scale.pack(fill=tk.X, pady=5)
    
    def create_post_processing_tab(self):
        """Create post-processing tab"""
        post_frame = ttk.Frame(self.notebook)
        self.notebook.add(post_frame, text="Post-Processing")
        
        # Post-processing effects
        effects_frame = ttk.LabelFrame(post_frame, text="Post-Processing Effects", padding=10)
        effects_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create scrollable frame for effects
        canvas = tk.Canvas(effects_frame, bg='#1a1a1a')
        scrollbar = ttk.Scrollbar(effects_frame, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Post-processing variables
        self.bloom_enabled_var = tk.BooleanVar(value=True)
        self.bloom_intensity_var = tk.DoubleVar(value=1.0)
        self.dof_enabled_var = tk.BooleanVar(value=True)
        self.dof_focus_distance_var = tk.DoubleVar(value=10.0)
        self.motion_blur_enabled_var = tk.BooleanVar(value=True)
        self.ao_enabled_var = tk.BooleanVar(value=True)
        self.ssr_enabled_var = tk.BooleanVar(value=True)
        self.vignette_enabled_var = tk.BooleanVar(value=True)
        self.chromatic_aberration_var = tk.BooleanVar(value=True)
        self.grain_enabled_var = tk.BooleanVar(value=True)
        
        # Bloom settings
        bloom_frame = ttk.LabelFrame(scrollable_frame, text="Bloom", padding=10)
        bloom_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(bloom_frame, text="Enable Bloom", variable=self.bloom_enabled_var).pack(anchor=tk.W)
        ttk.Label(bloom_frame, text="Intensity:").pack(anchor=tk.W, pady=(10, 0))
        bloom_intensity_scale = ttk.Scale(bloom_frame, from_=0.0, to=3.0, variable=self.bloom_intensity_var, orient=tk.HORIZONTAL)
        bloom_intensity_scale.pack(fill=tk.X, pady=5)
        
        # Depth of Field settings
        dof_frame = ttk.LabelFrame(scrollable_frame, text="Depth of Field", padding=10)
        dof_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(dof_frame, text="Enable Depth of Field", variable=self.dof_enabled_var).pack(anchor=tk.W)
        ttk.Label(dof_frame, text="Focus Distance:").pack(anchor=tk.W, pady=(10, 0))
        dof_focus_scale = ttk.Scale(dof_frame, from_=1.0, to=100.0, variable=self.dof_focus_distance_var, orient=tk.HORIZONTAL)
        dof_focus_scale.pack(fill=tk.X, pady=5)
        
        # Motion Blur
        motion_blur_frame = ttk.LabelFrame(scrollable_frame, text="Motion Blur", padding=10)
        motion_blur_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(motion_blur_frame, text="Enable Motion Blur", variable=self.motion_blur_enabled_var).pack(anchor=tk.W)
        
        # Ambient Occlusion
        ao_frame = ttk.LabelFrame(scrollable_frame, text="Ambient Occlusion", padding=10)
        ao_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(ao_frame, text="Enable Ambient Occlusion", variable=self.ao_enabled_var).pack(anchor=tk.W)
        
        # Screen Space Reflections
        ssr_frame = ttk.LabelFrame(scrollable_frame, text="Screen Space Reflections", padding=10)
        ssr_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(ssr_frame, text="Enable Screen Space Reflections", variable=self.ssr_enabled_var).pack(anchor=tk.W)
        
        # Vignette
        vignette_frame = ttk.LabelFrame(scrollable_frame, text="Vignette", padding=10)
        vignette_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(vignette_frame, text="Enable Vignette", variable=self.vignette_enabled_var).pack(anchor=tk.W)
        
        # Chromatic Aberration
        ca_frame = ttk.LabelFrame(scrollable_frame, text="Chromatic Aberration", padding=10)
        ca_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(ca_frame, text="Enable Chromatic Aberration", variable=self.chromatic_aberration_var).pack(anchor=tk.W)
        
        # Film Grain
        grain_frame = ttk.LabelFrame(scrollable_frame, text="Film Grain", padding=10)
        grain_frame.pack(fill=tk.X, pady=5)
        
        ttk.Checkbutton(grain_frame, text="Enable Film Grain", variable=self.grain_enabled_var).pack(anchor=tk.W)
        
        # Pack canvas and scrollbar
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
    
    def create_export_tab(self):
        """Create export tab"""
        export_frame = ttk.Frame(self.notebook)
        self.notebook.add(export_frame, text="Export")
        
        # Export settings
        settings_frame = ttk.LabelFrame(export_frame, text="Export Settings", padding=10)
        settings_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Platform
        ttk.Label(settings_frame, text="Target Platform:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.platform_var = tk.StringVar(value="Standalone")
        platform_combo = ttk.Combobox(settings_frame, textvariable=self.platform_var,
                                    values=["Standalone", "WebGL", "iOS", "Android"], state="readonly")
        platform_combo.grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # Build path
        ttk.Label(settings_frame, text="Build Path:").grid(row=1, column=0, sticky=tk.W, pady=5)
        build_path_frame = ttk.Frame(settings_frame)
        build_path_frame.grid(row=1, column=1, sticky=tk.W, pady=5)
        
        self.build_path_var = tk.StringVar(value="./builds")
        ttk.Entry(build_path_frame, textvariable=self.build_path_var, width=40).pack(side=tk.LEFT)
        ttk.Button(build_path_frame, text="Browse", command=self.browse_build_path).pack(side=tk.LEFT, padx=(5, 0))
        
        # Export actions
        actions_frame = ttk.LabelFrame(export_frame, text="Export Actions", padding=10)
        actions_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(actions_frame, text="Build Project", command=self.build_project).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(actions_frame, text="Export Assets", command=self.export_assets).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(actions_frame, text="Create Package", command=self.create_package).pack(side=tk.LEFT)
    
    def load_unity_status(self):
        """Load Unity installation status"""
        unity_version = self.unity_engine.get_latest_unity_version()
        if unity_version:
            self.status_label.config(text=f"Unity {unity_version['version']} detected")
            
            # Populate Unity version combo
            versions = [v['version'] for v in self.unity_engine.unity_versions]
            self.unity_version_combo['values'] = versions
            if versions:
                self.unity_version_combo.set(versions[0])
        else:
            self.status_label.config(text="No Unity installation found")
    
    def browse_project_path(self):
        """Browse for project path"""
        path = filedialog.askdirectory(title="Select Project Directory")
        if path:
            self.project_path_var.set(path)
    
    def browse_build_path(self):
        """Browse for build path"""
        path = filedialog.askdirectory(title="Select Build Directory")
        if path:
            self.build_path_var.set(path)
    
    def create_project(self):
        """Create a new Unity project"""
        try:
            project_name = self.project_name_var.get()
            project_path = os.path.join(self.project_path_var.get(), project_name)
            
            # Create project
            settings = self.unity_engine.create_lifelike_visual_project(project_name, project_path)
            
            # Apply current visual settings
            self.apply_current_visual_settings()
            
            self.current_project = project_path
            messagebox.showinfo("Success", f"Project '{project_name}' created successfully!")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create project: {str(e)}")
    
    def open_project(self):
        """Open existing Unity project"""
        project_path = filedialog.askdirectory(title="Select Unity Project")
        if project_path:
            self.current_project = project_path
            messagebox.showinfo("Success", f"Project opened: {project_path}")
    
    def launch_unity(self):
        """Launch Unity with current project"""
        if not self.current_project:
            messagebox.showerror("Error", "No project selected")
            return
        
        try:
            success = self.unity_engine.launch_unity_project(self.current_project)
            if success:
                messagebox.showinfo("Success", "Unity launched successfully!")
            else:
                messagebox.showerror("Error", "Failed to launch Unity")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to launch Unity: {str(e)}")
    
    def apply_quality_preset(self):
        """Apply selected quality preset"""
        preset = self.quality_preset_var.get()
        self.unity_engine.apply_visual_preset(preset)
        messagebox.showinfo("Success", f"Applied {preset} quality preset")
    
    def apply_current_visual_settings(self):
        """Apply current visual settings to Unity engine"""
        self.unity_engine.visual_settings.update({
            'ray_tracing': self.ray_tracing_var.get(),
            'real_time_gi': self.real_time_gi_var.get(),
            'volumetric_lighting': self.volumetric_lighting_var.get(),
            'screen_space_reflections': self.screen_space_reflections_var.get(),
            'ambient_occlusion': self.ambient_occlusion_var.get(),
            'bloom': self.bloom_var.get(),
            'depth_of_field': self.depth_of_field_var.get(),
            'motion_blur': self.motion_blur_var.get(),
            'anti_aliasing': self.anti_aliasing_var.get(),
            'shadow_quality': self.shadow_quality_var.get(),
            'texture_quality': self.texture_quality_var.get(),
            'vsync': self.vsync_var.get(),
            'frame_rate_target': self.frame_rate_var.get()
        })
    
    def create_scene(self):
        """Create a new scene"""
        try:
            scene_name = self.scene_name_var.get()
            scene_path = os.path.join(self.current_project, "Assets", "Scenes") if self.current_project else "./scenes"
            
            scene_data = self.renderer.create_lifelike_scene(scene_name, scene_path)
            self.current_scene = scene_data
            
            # Update scene tree
            self.update_scene_tree()
            
            messagebox.showinfo("Success", f"Scene '{scene_name}' created successfully!")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create scene: {str(e)}")
    
    def add_lighting(self):
        """Add lighting to current scene"""
        if not self.current_scene:
            messagebox.showerror("Error", "No scene selected")
            return
        
        try:
            lights = self.renderer.add_lifelike_lighting(self.current_scene)
            self.update_scene_tree()
            messagebox.showinfo("Success", f"Added {len(lights)} lights to scene")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to add lighting: {str(e)}")
    
    def add_camera(self):
        """Add camera to current scene"""
        if not self.current_scene:
            messagebox.showerror("Error", "No scene selected")
            return
        
        try:
            camera = self.renderer.add_lifelike_camera(self.current_scene)
            self.update_scene_tree()
            messagebox.showinfo("Success", "Camera added to scene")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to add camera: {str(e)}")
    
    def save_scene(self):
        """Save current scene"""
        if not self.current_scene:
            messagebox.showerror("Error", "No scene to save")
            return
        
        try:
            # Save scene data
            scene_path = os.path.join(self.current_project, "Assets", "Scenes", f"{self.current_scene['name']}.json")
            with open(scene_path, 'w') as f:
                json.dump(self.current_scene, f, indent=2)
            
            messagebox.showinfo("Success", "Scene saved successfully!")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save scene: {str(e)}")
    
    def update_scene_tree(self):
        """Update scene hierarchy tree"""
        # Clear existing items
        for item in self.scene_tree.get_children():
            self.scene_tree.delete(item)
        
        if not self.current_scene:
            return
        
        # Add scene root
        scene_root = self.scene_tree.insert("", "end", text=self.current_scene['name'], values=("Scene", ""))
        
        # Add cameras
        for camera in self.current_scene['cameras']:
            self.scene_tree.insert(scene_root, "end", text=camera['type'], values=("Camera", f"FOV: {camera['field_of_view']}"))
        
        # Add lights
        for light in self.current_scene['lights']:
            self.scene_tree.insert(scene_root, "end", text=f"{light['type']} Light", values=("Light", f"Intensity: {light['intensity']}"))
        
        # Add objects
        for obj in self.current_scene['objects']:
            self.scene_tree.insert(scene_root, "end", text=obj.get('name', 'Object'), values=("Object", ""))
    
    def create_material(self, material_type):
        """Create a predefined material"""
        if not self.current_project:
            messagebox.showerror("Error", "No project selected")
            return
        
        try:
            materials_path = os.path.join(self.current_project, "Assets", "Materials")
            self.unity_engine.create_lifelike_materials(materials_path)
            
            # Update material list
            self.update_material_list()
            
            messagebox.showinfo("Success", f"Created {material_type} material")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create material: {str(e)}")
    
    def create_custom_material(self):
        """Create a custom material"""
        # This would open a material editor dialog
        messagebox.showinfo("Info", "Custom material editor not implemented yet")
    
    def update_material_list(self):
        """Update material listbox"""
        self.material_listbox.delete(0, tk.END)
        
        if not self.current_project:
            return
        
        materials_path = os.path.join(self.current_project, "Assets", "Materials")
        if os.path.exists(materials_path):
            for file in os.listdir(materials_path):
                if file.endswith('.mat'):
                    self.material_listbox.insert(tk.END, file[:-4])
    
    def build_project(self):
        """Build Unity project"""
        if not self.current_project:
            messagebox.showerror("Error", "No project selected")
            return
        
        messagebox.showinfo("Info", "Build functionality not implemented yet")
    
    def export_assets(self):
        """Export project assets"""
        if not self.current_project:
            messagebox.showerror("Error", "No project selected")
            return
        
        messagebox.showinfo("Info", "Asset export functionality not implemented yet")
    
    def create_package(self):
        """Create Unity package"""
        if not self.current_project:
            messagebox.showerror("Error", "No project selected")
            return
        
        messagebox.showinfo("Info", "Package creation functionality not implemented yet")

def main():
    """Main function to launch the Unity integration GUI"""
    root = tk.Tk()
    app = UnityIntegrationGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main() 