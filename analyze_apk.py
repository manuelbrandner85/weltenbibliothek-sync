#!/usr/bin/env python3
"""
APK Analysis Tool for Weltenbibliothek
Extracts and compares APK metadata and features
"""

import zipfile
import json
import xml.etree.ElementTree as ET
from pathlib import Path
import sys

def analyze_apk(apk_path):
    """Extract basic metadata from APK"""
    print(f"\n{'='*60}")
    print(f"Analyzing: {Path(apk_path).name}")
    print(f"{'='*60}")
    
    results = {
        'path': str(apk_path),
        'size_mb': round(Path(apk_path).stat().st_size / (1024*1024), 2),
        'features': [],
        'libraries': [],
        'assets': []
    }
    
    try:
        with zipfile.ZipFile(apk_path, 'r') as apk:
            # List all files
            all_files = apk.namelist()
            
            # Check for AndroidManifest.xml
            if 'AndroidManifest.xml' in all_files:
                print("\n✅ AndroidManifest.xml found")
            
            # Analyze native libraries
            lib_files = [f for f in all_files if f.startswith('lib/') and f.endswith('.so')]
            unique_libs = set([Path(f).name for f in lib_files])
            results['libraries'] = sorted(unique_libs)
            
            print(f"\n📚 Native Libraries ({len(unique_libs)}):")
            for lib in sorted(unique_libs)[:10]:  # Show first 10
                print(f"  - {lib}")
            if len(unique_libs) > 10:
                print(f"  ... and {len(unique_libs) - 10} more")
            
            # Analyze DEX files
            dex_files = [f for f in all_files if f.endswith('.dex')]
            print(f"\n📦 DEX Files: {len(dex_files)}")
            for dex in dex_files:
                size_mb = round(apk.getinfo(dex).file_size / (1024*1024), 2)
                print(f"  - {dex}: {size_mb} MB")
            
            # Check for specific features based on libraries
            feature_indicators = {
                'agora': 'Video/Audio Calls (Agora RTC)',
                'flutter': 'Flutter Framework',
                'firebase': 'Firebase Integration',
                'pdfium': 'PDF Viewing',
                'video': 'Video Processing'
            }
            
            detected_features = []
            for indicator, feature in feature_indicators.items():
                if any(indicator in lib.lower() for lib in unique_libs):
                    detected_features.append(feature)
            
            results['features'] = detected_features
            
            print(f"\n🎯 Detected Features:")
            for feature in detected_features:
                print(f"  ✅ {feature}")
            
            # Analyze assets
            asset_files = [f for f in all_files if f.startswith('assets/')]
            print(f"\n📁 Assets: {len(asset_files)} files")
            
            # Check for Flutter assets
            flutter_assets = [f for f in asset_files if 'flutter_assets' in f]
            if flutter_assets:
                print(f"  - Flutter assets: {len(flutter_assets)}")
            
            # Size breakdown
            architectures = {}
            for f in lib_files:
                arch = f.split('/')[1] if len(f.split('/')) > 1 else 'unknown'
                if arch not in architectures:
                    architectures[arch] = 0
                architectures[arch] += apk.getinfo(f).file_size
            
            print(f"\n🏗️  Architecture Breakdown:")
            for arch, size in sorted(architectures.items()):
                print(f"  - {arch}: {round(size / (1024*1024), 2)} MB")
            
    except Exception as e:
        print(f"❌ Error analyzing APK: {e}")
        results['error'] = str(e)
    
    return results

def compare_apks(apk1_path, apk2_path):
    """Compare two APKs"""
    print(f"\n{'='*60}")
    print("📊 COMPARISON")
    print(f"{'='*60}")
    
    results1 = analyze_apk(apk1_path)
    results2 = analyze_apk(apk2_path)
    
    print(f"\n{'='*60}")
    print("🔍 DIFFERENCES")
    print(f"{'='*60}")
    
    # Compare libraries
    libs1 = set(results1['libraries'])
    libs2 = set(results2['libraries'])
    
    only_in_1 = libs1 - libs2
    only_in_2 = libs2 - libs1
    common = libs1 & libs2
    
    print(f"\n📚 Library Comparison:")
    print(f"  - Common libraries: {len(common)}")
    print(f"  - Only in {Path(apk1_path).name}: {len(only_in_1)}")
    print(f"  - Only in {Path(apk2_path).name}: {len(only_in_2)}")
    
    if only_in_2:
        print(f"\n✨ New libraries in Build 179:")
        for lib in sorted(only_in_2)[:10]:
            print(f"  + {lib}")
        if len(only_in_2) > 10:
            print(f"  ... and {len(only_in_2) - 10} more")
    
    # Compare features
    features1 = set(results1['features'])
    features2 = set(results2['features'])
    new_features = features2 - features1
    
    if new_features:
        print(f"\n🎉 New Features in Build 179:")
        for feature in new_features:
            print(f"  + {feature}")
    
    # Compare sizes
    size_diff = results2['size_mb'] - results1['size_mb']
    print(f"\n📊 Size Comparison:")
    print(f"  - Current: {results1['size_mb']} MB")
    print(f"  - Build 179: {results2['size_mb']} MB")
    print(f"  - Difference: {size_diff:+.2f} MB")

if __name__ == '__main__':
    current_apk = '/home/user/webapp/app-release.apk'
    build179_apk = '/home/user/webapp/weltenbibliothek_apk_standalone/Weltenbibliothek_Build179.apk'
    
    if Path(current_apk).exists() and Path(build179_apk).exists():
        compare_apks(current_apk, build179_apk)
    else:
        print("❌ APK files not found!")
        sys.exit(1)
