# Import necessary packages
# pip install git+https://github.com/ronald-jaepel/PyCORN.git@testbranch  # v0.19
# pip install plotly

import plotly.graph_objs as go
from pycorn import pc_uni6

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

def get_curve_name(curve):
    """Extract a more descriptive name for the curve."""
    metadata = curve.get('Metadata', {})
    better_name = metadata.get('DescriptiveName', None)
    return better_name if better_name else "Unknown Curve"  # Fallback if DescriptiveName doesn't exist

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

def plot_curves(curves, title="Chromatograms", x_label="Volume (ml)", y_label="Absorbance (mAU)", template='plotly_dark'):
    """Plot specified curves using Plotly."""
    fig = go.Figure()

    for curve_type, curve_dict in curves.items():
        for key, curve in curve_dict.items():
            volumes = curve.get('CoordinateData.Volumes', [])
            amplitudes = curve.get('CoordinateData.Amplitudes', [])
            better_name = get_curve_name(curve)

            if isinstance(volumes, bytes):
                volumes = volumes.decode('utf-8')
            if isinstance(amplitudes, bytes):
                amplitudes = amplitudes.decode('utf-8')

            # Normalize non-UV curves
            if 'UV' not in key:
                amplitudes = normalize_y(amplitudes)

            fig.add_trace(go.Scatter(x=volumes, y=amplitudes, mode='lines', name=better_name))

    fig.update_layout(
        title=title,
        xaxis_title=x_label,
        yaxis_title=y_label,
        template=template
    )
    
    fig.show()

# Load data
data = load_data(FILE_PATH)

# Extract all curves
all_curves = extract_all_curves(data)
print(all_curves)

# Plot all curves
if all_curves:
    plot_curves(all_curves)
else:
    print("No data found.")
