# SMAjram: MATLAB Software for Synthetic Shahmukhi Character Image Generation

## Overview

SMAjram is a MATLAB-based software framework for generating synthetic Punjabi Shahmukhi character images. It supports generating base character images and controlled variations, including rotation, blurring, intensity combinations, and outlining.

The software supports research in optical character recognition (OCR), character recognition, and pattern recognition.

## Software Requirements

- **MATLAB R2024b (24.2)** is the tested reference environment.
- **Image Processing Toolbox (24.2)** was identified as a required product by MATLAB's dependency analysis of the seven MATLAB files.
- An Excel workbook containing character-context and font information is required to prepare the source resources.
- The required fonts must be installed in Windows before starting MATLAB.

MATLAB's dependency analysis identified MATLAB R2024b and the Image Processing Toolbox as required. MATLAB did not identify the Computer Vision Toolbox as required. Dependencies may vary if you modify optional features or code paths.

Compatibility with other MATLAB releases may vary. We observed figure-rendering differences in MATLAB R2025a and R2025b. In the developer's MATLAB R2026b environment, the additional Java font-directory step described below was not required.

## Repository Contents

| File | Purpose |
|---|---|
| `prepare_smajram_resources.m` | Prepares character and font resources from the input workbook. |
| `generate_smajram_characters.m` | Generates the base character images. |
| `smajram_rotation.m` | Generates rotated image variants. |
| `smajram_blur.m` | Generates blurred image variants. |
| `smajram_combination.m` | Generates image and background intensity combinations. |
| `smajram_outline.m` | Generates outlined image variants. |
| `build_smajram_ground_truth.m` | Collects image filenames and English class labels and checks technical image properties. |

## Input Resources

The resource-preparation script uses this input workbook:

- `Shah_AjramnFont_Updated_clean.xlsx`

The workbook contains character-context information in the `ShahAjram` sheet and font information in the `Ajram_Fonts` sheet. The `gen guide` sheet provides a character list and global serial ID ranges for images in the different dataset folders.

The script `prepare_smajram_resources.m` generates:

- `shah_ajram240.mat`
- `font_list50.mat`

It also exports a human-readable character reference table, `shah_ajram_Tab.xlsx`. The character-generation workflow uses the `.mat` resource files.

## Font Requirements and Rendering Setup

Correct font configuration is essential for reproducing SMAjram character images. Generated images depend on the fonts listed in the source Excel workbook being available.

### Install fonts in Windows first

Install the required fonts in Windows before opening MATLAB. The source workbook `Shah_AjramnFont_Updated_clean.xlsx` contains the font names used by the generation workflow.

Some fonts are freely available, while others may require access through Adobe Creative Cloud or an applicable Adobe font service. Requirements vary by font. Obtain fonts from appropriate sources and follow their license terms. The software repository does not redistribute font files. Users are responsible for obtaining and installing fonts they are permitted to use.

### Keyboard and character-entry tools

Keyman and the Microsoft Urdu language support package, including the Urdu keyboard, to prepare character resources and enter Shahmukhi characters accurately. These tools are not required at runtime because the current image-generation workfWe used low uses ASCII class labels.

### Additional setup for MATLAB R2024b

In the developer's tested MATLAB R2024b environment, after installing fonts in Windows, the required font files were also copied to the following Java runtime font directory before MATLAB was launched:

`MATLAB path\sys\java\jre\win64\jre\lib\fonts`

This is an environment-specific workaround, not a universal MATLAB requirement. The path may vary depending on the MATLAB installation. Complete any required font setup before launching MATLAB.

This additional step was not required in the developer's MATLAB R2026b environment. Install the fonts in Windows and test rendering in your own MATLAB version before generating a large dataset.

## Execution Order

Run the core generation scripts in the following order:

1. `prepare_smajram_resources.m`
2. `generate_smajram_characters.m`
3. `smajram_rotation.m`
4. `smajram_blur.m`
5. `smajram_combination.m`
6. `smajram_outline.m`

Run `build_smajram_ground_truth.m` separately for each required image folder and worksheet.

### Function dependencies

- `prepare_smajram_resources.m` creates the resources required by the character generator.
- `generate_smajram_characters.m` produces the base images in `AjramMain`.
- `smajram_rotation.m` reads the base images and produces rotated images in its configured destination folder.
- `smajram_blur.m`, `smajram_combination.m`, and `smajram_outline.m` use the rotated images as their source and produce their respective output folders. Configure each script's `source_folder` to the exact local rotation_folder name.

The combination and outline scripts are separate transformations of the rotated images; neither uses the other's output as its input.

## Configuration

Each generation script has a configuration section near the beginning. Before running it, check the source folder, destination folder, input image extension, selected source indices (where applicable), output-ID range (where applicable), and transformation parameters.

Folder names are configurable. For example, the rotation source folder may be named `AjramRot`, `Ajram-Rotations`, or a local name such as `RotE`. Set `source_folder` to the exact folder name used in your working directory.

Progress reporting and visual inspection can be enabled or disabled where supported. Visual inspection is optional and may add processing overhead.

## Batch-wise Generation

The Blur, Combination, and Outline scripts support batch processing of selected source images. This lets you generate a large output collection in smaller runs instead of one long run for an entire category.

### How the batch settings work

- `img_list` selects **positions in the sorted source-file list**. These are not the global IDs embedded in the filenames. For example, `img_list = 1:1500` selects the first 1,500 source files after sorting.
- `output_id_start` and `output_id_end` define the inclusive global output-ID range for that batch. Use the exact ranges in the SMAjram Generation Guide (`gen guide` sheet).
- The number of IDs in the configured range is `output_id_end - output_id_start + 1`. It must equal the expected number of outputs for the selected inputs.
- Use non-overlapping source-index ranges for successive batches, and follow the matching source-index and output-ID ranges in the generation guide. Do not estimate or reuse ranges from another category.
- Set `destination_folder` to the intended output folder. Batches can share the same destination folder when their output-ID ranges don't overlap.
- Existing output filenames are protected in the generation scripts: if a generated filename already exists, the script stops rather than overwriting it.
- The scripts do not automatically resume an interrupted batch or roll back files already generated before an error. After an interruption, inspect the output folder and configuration before deciding how to continue; do not simply rerun the same range into a folder containing generated files.

### Outputs per selected input

With the default transformation parameters, each selected input produces:

| Script | Outputs per input | Expected output count |
|---|---:|---|
| `smajram_blur.m` | 4 | `numel(img_list) * 4` |
| `smajram_combination.m` | 13 | `numel(img_list) * 13` |
| `smajram_outline.m` | 37 | `numel(img_list) * 37` |

Before starting a batch, check that the number of IDs from `output_id_start` through `output_id_end` matches the calculated output count. The scripts validate this configuration and stop if the counts don't match.

### Computational resources and storage

Resource use depends on the number of selected inputs, the output transformation, MATLAB version, disk speed, and available storage. Ensure the destination drive has enough free space for the images, and allow long processing times for large batches. Use a reliable power supply for long-running generation jobs.

In the developer's tests, a 288,000-image Blur subfolder took about 52 minutes on the test computer. Smaller validation runs of 1,500 inputs took approximately 1 minute for Blur, 3.5 minutes for Combination, and 9.3 minutes for Outline. These timings are from the tested environment, not performance guarantees; actual times will vary by computer and configuration.

For reproducibility, retain the configured parameter values, input resources, MATLAB version, source and destination folder names, batch ranges, and execution order.

## Ground-Truth Generation

The ground-truth collector:

1. Collects image files from the configured source folder, including subfolders.
2. Checks whether each image can be read.
3. Checks that the file extension agrees with the image's internal format.
4. Checks that image dimensions are positive and that the image is not completely flat.
5. Records image width, height, channel count, and bit depth.
6. Extracts the English class label from the filename.
7. Exports the ground-truth table and technical specifications to separate Excel workbooks.

If any image fails the technical checks, the script writes the affected paths and reasons to a separate workbook and stops ground-truth generation. It also stops if filenames do not match the expected label convention.

The expected filename convention places the English class label after the final underscore and before the file extension. For example:

`g00000310(B11)(A0)(s100){Adobe Arabic}_Naon.png`

The extracted label for this example is `Naon`.

The technical checks help identify file and image anomalies; they do not establish that every image is semantically correct or that every rendered character is visually accurate. Before running it, configure the root folder, target folder, ground-truth workbook and sheet, and technical-specification output in the ground-truth script.

## Output

The software generates PNG character images in separate folders for base images and supported transformations.

In the documented production configuration, the complete SMAjram dataset comprises 19,872,000 images. Actual output counts depend on the configured parameters and input files.

## Repository maintenance note

The current repository includes maintenance improvements to configuration validation, batch-wise generation, and overwrite protection. These changes improve usability and reproducibility. The published `v1.0.0` release remains the historical snapshot of the software at that release; the current default branch may include subsequent maintenance changes. Do not assume these later changes were part of the original dataset-generation workflow unless independently documented.

## Reproducibility and compatibility

For reproducible results, retain the configured parameter values, input resources, MATLAB version, and execution order. We developed and tested the software in MATLAB R2024b. We observed figure-rendering differences in MATLAB R2025a and R2025b; users should verify visual outputs in their own MATLAB environment.

## License

SMAjram source code is released under the MIT License. See the [`LICENSE`](LICENSE) file for the complete terms.

The MIT License applies to the SMAjram software source code. It does not grant permission to redistribute third-party fonts or other resources that are subject to separate licenses. Users are responsible for obtaining and using these resources in accordance with their respective license terms.

The MATLAB license and any MathWorks product licenses are separate from the SMAjram software license. Users must have their own valid licenses for MATLAB and any required toolboxes.

## Citation

If you use SMAjram in your research, cite the software version used. Add the recommended software citation and BibTeX entry here using the finalized software archive metadata and DOI.

Until the citation details are finalized, cite the GitHub repository URL and identify the version or commit used.

## Support

For questions, bug reports, or reproducibility issues, please use the **Issues** section of this GitHub repository.
