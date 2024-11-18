package main

import (
	"archive/zip"
	"encoding/base64"
	"encoding/xml"
	"fmt"
	"log"
	"strings"

	"github.com/xuri/excelize/v2"
)

// Define structures based on XML data
type Result struct {
	XMLName               xml.Name       `xml:"Result"`
	Name                  string         `xml:"Name"`
	RunType               string         `xml:"RunType"`
	ResultRunInformations []RunInfo      `xml:"ResultRunInformation"`
	Chromatograms         []Chromatogram `xml:"Chromatograms>Chromatogram"`
}

type RunInfo struct {
	RunInformationType string `xml:"RunInformationType,attr"`
	RunInformation     string `xml:"RunInformation"`
}

type ColumnInfoDecoded struct {
	XMLName xml.Name        `xml:"usedColumns"`
	Columns []ColumnRunInfo `xml:"column"`
}

type ColumnRunInfo struct {
	Name   string `xml:"name"`
	Volume string `xml:"volume"`
}

type UVCurve struct {
	BinaryCurvePointsFileName string `xml:"BinaryCurvePointsFileName"`
}

type Chromatogram struct {
	Title  string  `xml:"ChromatogramName"`
	Curves []Curve `xml:"Curves>Curve"`
}

type Curve struct {
	DataType    string       `xml:"CurveDataType,attr"`
	Name        string       `xml:"Name"`
	CurvePoints []CurvePoint `xml:"CurvePoints>CurvePoint"`
}

type CurvePoint struct {
	FileName string `xml:"BinaryCurvePointsFileName"`
}

func main() {
	zipFilePath := "E:/transfer/20241106_134_1_aMo_Superdex 75 120 ml 500 µl injection new 001 001.zip"
	outputFilePath := "output.xlsx"

	// Open the ZIP file
	r, err := zip.OpenReader(zipFilePath)
	if err != nil {
		log.Fatal(err)
	}
	defer r.Close()

	var result Result

	// Iterate through files in the zip
	for _, f := range r.File {
		if strings.HasSuffix(f.Name, ".xml") {
			rc, err := f.Open()
			if err != nil {
				log.Fatal(err)
			}
			defer rc.Close()

			contents := make([]byte, f.UncompressedSize64)
			rc.Read(contents)

			xml.Unmarshal(contents, &result)
		}
	}
	fmt.Printf("result: %v\n", result)
	if err := createExcel(result, r, outputFilePath); err != nil {
		log.Fatalf("Failed to create Excel file: %v", err)
	}
}
func createExcel(result Result, r *zip.ReadCloser, filePath string) error {
	f := excelize.NewFile()

	// Create sheets and add data
	index, err := f.NewSheet("Result")
	if err != nil {
		return err
	}
	f.SetCellValue("Result", "A1", "Name")
	f.SetCellValue("Result", "B1", result.Name)
	f.SetCellValue("Result", "A2", "RunType")
	f.SetCellValue("Result", "B2", result.RunType)

	// Add column information data
	colIndex := 3
	f.SetCellValue("Result", fmt.Sprintf("A%d", colIndex), "Column Information")
	colIndex++

	for _, runInfo := range result.ResultRunInformations {
		if runInfo.RunInformationType == "ColumnInformation" {
			// Decode base64 string
			decodedRunInfo, err := base64.StdEncoding.DecodeString(runInfo.RunInformation)
			if err != nil {
				return err
			}

			var colInfoDecoded ColumnInfoDecoded
			xml.Unmarshal(decodedRunInfo, &colInfoDecoded)

			for _, col := range colInfoDecoded.Columns {
				f.SetCellValue("Result", fmt.Sprintf("A%d", colIndex), "Name")
				f.SetCellValue("Result", fmt.Sprintf("B%d", colIndex), col.Name)
				colIndex++
				f.SetCellValue("Result", fmt.Sprintf("A%d", colIndex), "Volume")
				f.SetCellValue("Result", fmt.Sprintf("B%d", colIndex), col.Volume)
				colIndex++
			}
		}
	}

	// Add UV curve data
	curveIndex := colIndex + 1
	f.SetCellValue("Result", fmt.Sprintf("A%d", curveIndex), "UV Curves")

	for _, chromatogram := range result.Chromatograms {
		for _, curve := range chromatogram.Curves {
			if curve.DataType == "UV" {
				for _, point := range curve.CurvePoints {
					cell := fmt.Sprintf("A%d", curveIndex)
					f.SetCellValue("Result", cell, fmt.Sprintf("Chromatogram: %s, BinaryCurveFileName: %s", chromatogram.Title, point.FileName))
					curveIndex++
				}
			}
		}
		curveIndex++
	}

	// Set the active sheet
	f.SetActiveSheet(index)

	// Save the spreadsheet
	if err := f.SaveAs(filePath); err != nil {
		return err
	}
	return nil
}
