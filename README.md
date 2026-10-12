# SMAjram: MATLAB Software for Synthetic Shahmukhi Character Image Generation

## Overview

SMAjram is a MATLAB-based software framework for generating synthetic Punjabi Shahmukhi character images. 
It supports generating base character images and controlled variations, including rotation, blurring, intensity combinations, and outlining.

The software supports research in optical character recognition (OCR), character recognition, and pattern recognition.

## Software Requirements

- **MATLAB R2024b (24.2)** is the tested reference environment.
- **Image Processing Toolbox (24.2)** was identified as a required product by MATLAB's dependency analysis of the seven cleaned MATLAB files.
- An Excel workbook containing the character-context and font information is required to prepare the source resources.
- The required fonts must be installed in Windows before starting MATLAB.

MATLAB's dependency analysis identified MATLAB R2024b and Image Processing Toolbox as required products. 
MATLAB did not identify the Computer Vision Toolbox as required. Dependencies may vary if you modify optional features or code paths.

Compatibility with other MATLAB releases may vary. MATLAB R2025a and b figure-rendering differences were observed during testing, 
while the developer's MATLAB R2026b setup did not require the same manual Java font directory step described below. 

## Repository Contents

| File | Purpose |
|---|---|
| `prepare_smajram_resources.m` | Prepares character and font resources from the input workbook. |
| `generate_smajram_characters.m`| Generates the base character images. |
| `smajram_rotation.m` | Generates rotated image variants. |
| `smajram_blur.m` | Generates blurred image variants. |
| `smajram_combination.m` | Generates image and background intensity combinations. |
| `smajram_outline.m` | Generates outlined image variants. |
| `build_smajram_ground_truth.m` | Collects image filenames and English class labels into an Excel workbook. |

## Input Resources

The resource-preparation function uses the following input workbook:

- `Shah_AjramnFont_Updated_clean.xlsx`

The workbook contains the character-context and font information required to prepare the resources. 
The program prepare_smajram_resources.m will generate:

- `shah_ajram240.mat`
- `font_list50.mat`

The character-generation workflow uses these resource files.

## Font Requirements and Rendering Setup

Correct font configuration is essential for reproducing SMAjram character images. 
The generated images depend on the fonts listed in the source Excel workbook being available.

### Install Fonts in Windows First

Install the required font files in Windows before opening MATLAB. The source workbook `Shah_AjramnFont_Updated_clean.xlsx` contains the exact font names MATLAB recognizes and uses in the generation workflow.

Some fonts are freely available, while others may require access through Adobe Creative Cloud or an applicable Adobe font service. Requirements vary by font. 
Obtain fonts from their appropriate sources and follow their license terms. The software repository does not redistribute font files. Users are responsible for obtaining and installing fonts they are permitted to use.

### Keyboard and Character Entry Tools

We used Keyman and the Microsoft Urdu language support package, including the Urdu keyboard, to prepare the character resources and enter Shahmukhi characters accurately. These tools were needed for resource preparation and character entry but aren't required at runtime because the current image-generation workflow uses ASCII class labels.

### Additional Setup for MATLAB R2024b

In the developer's tested MATLAB R2024b environment, after installing the fonts in Windows, the required font files were also copied to the following Java runtime font directory before MATLAB was launched:

`MATLAB path\sys\java\jre\win64\jre\lib\fonts`

This is an environment-specific workaround, not a universal MATLAB requirement. The path may vary depending on where you install MATLAB. Complete any required font setup before launching MATLAB.

In the developer's MATLAB R2026b environment, this additional step was not required. Users should install the fonts in Windows and test rendering in their own MATLAB version before generating a large dataset.

## Execution Order

Run the core generation functions in the following order:

1. `prepare_smajram_resources.m`
2. `generate_smajram_characters.m`
3. `smajram_rotation.m`
4. `smajram_blur.m`
5. `smajram_combination.m`
6. `smajram_outline.m`

The ground-truth collector, `build_smajram_ground_truth.m`, is run separately for each required image folder and worksheet.

### Function Dependencies

- `prepare_smajram_resources.m` creates the resources required by the character generator.
- `generate_smajram_characters.m` produces the base images in `AjramMain`.
- `smajram_rotation.m` reads the base images and produces rotated images in `AjramRot`.
- `smajram_blur.m`, `smajram_combination.m`, and `smajram_outline.m` use `AjramRot` as their source and produce their respective output folders.

The combination and outline functions are separate transformations of the rotated images; neither uses the other's output as its input.

## Configuration

Each generation function provides configurable parameters near the beginning of the script. Configure the source folder, destination folder, and relevant transformation parameters before running a function.

You can enable or disable progress reporting and visual inspection where supported. Visual inspection is optional and may add processing overhead.

Use valid source and destination paths for your local environment. Ensure you have sufficient storage before generating large image collections. Keep a record of the configured parameters and execution order to reproduce an experiment.

## Ground-Truth Generation

The ground-truth collector:

1. Collects image files from the configured source folder, including subfolders.
2. Checks whether each image can be read.
3. Extracts the English class label from the filename.
4. Creates a table containing the filename and label.
5. Exports the table to the configured Excel workbook and worksheet.

If it finds unreadable files, it saves their paths to a separate workbook and stops ground-truth generation. The script reports filenames that do not match the expected label convention rather than silently accepting them.

The expected filename convention places the English class label after the final underscore and before the file extension. For example:

`g00000310(B11)(A0)(s100){Adobe Arabic}_Naon.png`

The extracted label for this example is `Naon`.

## Output

The software generates PNG character images in separate folders for the base images and the supported transformations.

In the documented production configuration, the complete SMAjram dataset comprises 19,872,000 images. Actual output counts depend on the configured parameters and input files.

## Reproducibility and Compatibility

For reproducible results, retain the configured parameter values, input resources, MATLAB version, and execution order. MATLAB R2024b is the reference environment in MATLAB R2024 b. We observed some figure-rendering differences in MATLAB R2025b; users should verify visual outputs in their own MATLAB environment.

## License

SMAjram source code is released under the MIT License. See the [`LICENSE`](LICENSE) file for the complete terms.

The MIT License applies to the SMAjram software source code. It does not grant permission to redistribute third-party fonts or other resources that are subject to separate licenses. Users are responsible for obtaining and using these resources in accordance with their respective license terms.

The MATLAB license and any MathWorks product licenses are separate from the SMAjram software license. Users must have their own valid licenses for MATLAB and any required toolboxes.

## Citation

If you use SMAjram in your research, please cite the software using the DOI provided by Zenodo. We will add the recommended citation and BibTeX entry here after we archive the software.

Until then, please cite the GitHub repository URL and identify the software version used.

## Support

For questions, bug reports, or reproducibility issues, please use the **Issues** section of this GitHub repository.
