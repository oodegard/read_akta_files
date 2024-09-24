import xml.etree.ElementTree as ET

def parse_chromatogram_xml(file_path):
    # Parse the XML file
    tree = ET.parse(file_path)
    root = tree.getroot()

    # Extract general chromatogram information
    chromatogram_name = root.find('ChromatogramName').text
    is_readonly = root.find('IsReadonly').text
    time_unit = root.find('TimeUnit').text
    volume_unit = root.find('VolumeUnit').text
    created = root.find('Created').text
    created_utc_offset = root.find('CreatedUtcOffsetMinutes').text

    print(f"Chromatogram Name: {chromatogram_name}")
    print(f"Is Read-only: {is_readonly}")
    print(f"Time Unit: {time_unit}")
    print(f"Volume Unit: {volume_unit}")
    print(f"Created: {created}")
    print(f"Created UTC Offset: {created_utc_offset}")

    # Iterate through all the curves in the file
    curves = root.find('Curves')
    for curve in curves.findall('Curve'):
        curve_name = curve.find('Name').text
        curve_type = curve.attrib['CurveDataType']
        curve_number = curve.find('CurveNumber').text
        amplitude_unit = curve.find('AmplitudeUnit').text
        
        print(f"\nCurve Name: {curve_name}")
        print(f"Curve Type: {curve_type}")
        print(f"Curve Number: {curve_number}")
        print(f"Amplitude Unit: {amplitude_unit}")

        # Curve points information
        curve_points = curve.find('CurvePoints')
        for curve_point in curve_points.findall('CurvePoint'):
            is_full_resolution = curve_point.find('IsFullResolution').text
            binary_curve_file = curve_point.find('BinaryCurvePointsFileName').text
            
            print(f"    Full Resolution: {is_full_resolution}")
            print(f"    Binary Curve File: {binary_curve_file}")

if __name__ == "__main__":
    # Provide the path to your XML file
    file_path = r"C:\Users\Øyvind\OneDrive - Universitetet i Oslo\Work\03_UiO\15_instrument_data\Akta\20240923_129_S01_amCh_unconjugated Superdex 75 120 ml 500 µl injection new 001 001\Chrom.1.Xml"
    parse_chromatogram_xml(file_path)
