from setuptools import setup, find_packages

setup(
    name="lilithos",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        'cryptography>=3.4.7',
        'aiohttp>=3.8.0',
        'pyyaml>=6.0',
    ],
    entry_points={
        'console_scripts': [
            'lilithctl=lilithos.cli:main',
        ],
    },
    python_requires='>=3.7',
)
