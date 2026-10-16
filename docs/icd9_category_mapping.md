# ICD-9 Diagnosis Category Mapping (Strack et al. 2014, Table 2)

Used to group diag_1 / diag_2 / diag_3 raw ICD-9 codes into clinical categories.

| Categories      | ICD-9 Code Ranges                                         |
| --------------- | --------------------------------------------------------- |
| Circulatory     | 390-459, 785                                              |
| Respiratory     | 460-519, 786                                              |
| Digestive       | 520-579, 787                                              |
| Diabetes        | 250.xx                                                    |
| Injury          | 800-999                                                   |
| Musculoskeletal | 710-739                                                   |
| Genitourinary   | 580-629, 788                                              |
| Neoplasms       | 140-239                                                   |
| Other           | 780, 781, 784, 790–799 (symptoms/ill-defined)             |
|                 | 240–279 excl. 250 (endocrine/metabolic, non-diabetes)     |
|                 | 680–709, 782 (skin)                                       |
|                 | 001–139 (infectious/parasitic)                            |
|                 | 290-319 (mental disorders)                                |
|                 | E-V codes (external causes / supplemental classification) |
|                 | 280-289 (blood/blood-forming organ)                       |
|                 | 320-359 (nervous system)                                  |
|                 | 630-679 (pregnancy/childbirth/puerperium)                 |
|                 | 360-389 (sense organs)                                    |
|                 | 740-759 (congenital anomalies)                            |

Note: original paper's Table 2 grouping was applied only to the PRIMARY diagnosis (diag_1)
for their analysis. For this project's schema we will apply the same grouping logic to
diag_1, diag_2, and diag_3 uniformly, since all three live in the same `diagnoses` table.
