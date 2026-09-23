# Climate archive contract

This reader expects Armstrong version 2 files named:

```text
bias_regrid_tas_0_2.5kyr.nc       variable tas
bias_regrid_pr_0_2.5kyr.nc        variable pr
regrid_landmask_0_2.5kyr.nc      variable sftlf
regrid_icefrac_0_2.5kyr.nc       variable sftgif
```

Other intervals use the same `<young>_<old>kyr.nc` naming convention. Dimensions
must be named `lon`, `lat`, `time`; variable dimension order is detected.
Coordinates must increase. Temperature must be in Celsius and precipitation in
mm/day. Every full 2.5 kyr file must contain 30,000 monthly climate values or
2,500 annual mask values. January is the first month; file time runs from the old
end towards the present. This is an explicit archive-specific contract, not a
generic CF time decoder. Do not substitute a different archive with renamed files.

The calibration stage uses BP relative to 1950. Extraction translates age into an
annual index from the file's old end. At a shared file boundary, the younger
interval is chosen. Monthly windows stay within one file, shifting at its edges.
Land/ice masks use the closest annual index, without time averaging. Climate
variables use the selected climatological averaging window.

Total precipitation (`pr`) is distinct from the archive's separate snowfall
variable. Its rates represent liquid-water-equivalent precipitation, not snow
depth, snow cover or snow persistence. The workflow does not estimate the latter
from precipitation alone. Temperature and precipitation predictors are climatic
associations, not direct measures of prey, vegetation or snow accessibility.

For 3x3 extraction only available land/ice-free neighbours contribute; a central
cell that is ice-covered or ocean is not rescued by neighbouring land. Mean
monthly climate is spatially averaged first, then seasonal/annual statistics are
calculated. Thus the warmest month of the average climate is not necessarily the
average of each cell's warmest month. Equal neighbour weights are used for this
local smoothing; regional areas/means use cos(latitude) weighting.

At projection times, ice gets suitability zero, ocean/missing gets NA. Available
land receives continuous MaxEnt/Gaussian scores. Ice cells remain in the land
area denominator. Country outlines are modern; masks represent palaeoland/ice.

The demo deliberately uses a much coarser geographic grid but exactly the same
time ordering, units and variable names so that it exercises the reader. It is
not a reduced-resolution scientific reconstruction.

External climate files are catalogued by path, interval and variable. Their
contents are not copied or hashed. Record the archive DOI/version and do not
modify shared files in place. A changed archive requires a new extraction run.
