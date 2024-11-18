# Import necessary packages
# pip install git+https://github.com/ronald-jaepel/PyCORN.git@testbranch  # v0.19
# pip install plotly

import plotly.graph_objs as go
from pycorn import pc_uni6
import xml.etree.ElementTree as ET
import re

# Define file path
FILE_PATH = r"E:\transfer\20241106_134_1_aMo_Superdex 75 120 ml 500 µl injection new 001 001.zip"

def load_data(file_path):
    """Load data from a zip file."""
    data = pc_uni6(file_path)
    data.load()
    return data

def extract_all_curves(data):
    """Extract all unique types of curves from the data."""
    extracted_data = {}
    for key, value in data.items():
        curve_type = key.split('_')[0]
        if isinstance(value, dict):  # Ensure the value is a dictionary
            if curve_type not in extracted_data:
                extracted_data[curve_type] = {}
            extracted_data[curve_type][key] = value
    return extracted_data

def normalize_y(data):
    """Normalize curve data other than UV."""
    if not data:
        return data  # Return unchanged if data is empty
    
    max_value = max(data)
    min_value = min(data)
    range_value = max_value - min_value
    if range_value > 0:
        normalized_data = [(val - min_value) / range_value for val in data]
        return normalized_data
    return data

def get_curve_mapping(all_curves):
    curve_mapping = {}
    if "StrategyData" in all_curves:
        strategy_data = all_curves["StrategyData"].get("StrategyData", {})
        strategy_xml = strategy_data.get("Xml", b"").decode("utf-8", errors="ignore")
        start_index = strategy_xml.find("<Curves>")
        end_index = strategy_xml.find("</Curves>") + len("</Curves>")
        
        if start_index != -1:
            cleaned_xml = strategy_xml[start_index:end_index].replace(",", "")
            
            try:
                root = ET.fromstring(cleaned_xml)
                
                for curve in root.findall(".//Curve"):
                    curve_number = curve.find("CurveNumber").text if curve.find("CurveNumber") is not None else "Unknown"
                    curve_name = curve.find("CurveName").text if curve.find("CurveName") is not None else "Unknown"
                    curve_mapping[curve_number] = curve_name
            
            except ET.ParseError as e:
                print(f"Failed to parse XML: {e}")
        
        else:
            print("No valid XML found in the input data.")
            
    return curve_mapping

def extract_curve_number_from_key(curve_key):
    """Extract the CurveNumber from the curve key."""
    match = re.search(r"_(\d+)_True$", curve_key)
    if match:
        return match.group(1)
    return None


def plot_curves(curves, title="Chromatograms", x_label="Volume (ml)", y_label="Absorbance (mAU)", template='plotly_dark'):
    """Plot specified curves using Plotly."""
    fig = go.Figure()  
    
    curve_map = get_curve_mapping(curves)   
    print(curve_map)
    
    for _, curve_dict in curves.items():        

        for key, curve in curve_dict.items():
            if key.endswith('_True'):
                curveID = extract_curve_number_from_key(key)
                print(curveID)
                curve_name = curve_map.get(str(curveID), "Unknown Curve")
                print(curve_name)

           
                volumes = curve.get('CoordinateData.Volumes', []) 
                amplitudes = curve.get('CoordinateData.Amplitudes', [])

                if isinstance(volumes, bytes):
                    volumes = volumes.decode('utf-8')
                if isinstance(amplitudes, bytes):
                    amplitudes = amplitudes.decode('utf-8')

                # Normalize non-UV curves
                if 'UV' not in key:
                    amplitudes = normalize_y(amplitudes)

                fig.add_trace(go.Scatter(x=volumes, y=amplitudes, mode='lines', name=curve_name))

    fig.update_layout(
        title=title,
        xaxis_title=x_label,
        yaxis_title=y_label,
        template=template
    )
    
    fig.show()

# Load data
data = load_data(FILE_PATH)

#print(data.keys())

# Extract all curves
all_curves = extract_all_curves(data)
#print(all_curves)




#print(all_curves.keys())


# Plot all curves

if all_curves:
    plot_curves(all_curves)
else:
    print("No data found.")

