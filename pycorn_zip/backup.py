# Install necessary packages
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

def plot_curves(curves, title="Chromatograms", x_label="Volume (ml)", y_label="Absorbance (mAU)", template='plotly_dark'):
    """Plot specified curves using Plotly."""
    fig = go.Figure()

    for curve_type, curve_dict in curves.items():
        for label, curve in curve_dict.items():
            volumes = curve.get('CoordinateData.Volumes', [])
            amplitudes = curve.get('CoordinateData.Amplitudes', [])
            if isinstance(volumes, bytes):
                volumes = volumes.decode('utf-8')
            if isinstance(amplitudes, bytes):
                amplitudes = amplitudes.decode('utf-8')
            fig.add_trace(go.Scatter(x=volumes, y=amplitudes, mode='lines', name=label))

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
