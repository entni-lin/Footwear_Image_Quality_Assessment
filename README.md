# Image features
This repository is in private for now (**but you can see it via Gitfront**) before I complete my dissertation :) <br>
There are four main features I've proposed to apply on footwear impression images (including high-quality Handiprints, relatively low-quality dust and blood impressions):
1. Texture analysis features via gray-level co-occurrence matrix (GLCM) in IDL: glcm_shoe.pro
2. Spatial information via magnitudes of pixels after applying the Sobel filters in IDL: spatial_information.pro
3. Fourier analysis in IDL and R: RUN "frequency_component_magnitude.pro" first and then "frequency_component_image_index_compute.R"
4. Wavelet analysis using the method and codes by Vu and Chandler (2012) in Matlab: fish_shoe.m, fish.m, fish_bb.m, and dwt_cdf97.m. Note that the last three files need to be downloaded and the dirdctory path need to be added to run the first file. <br>
P. V. Vu and D. M. Chandler, "A Fast Wavelet-Based Algorithm for Global and Local Image Sharpness Estimation," in IEEE Signal Processing Letters, vol. 19, no. 7, pp. 423-426, July 2012, doi: 10.1109/LSP.2012.2199980.
5. Totality/complexity (percentage of white pixels - referred as to impressions, perimeters of contours via OpenCV, and create images with bounding box + contours): totality.py
