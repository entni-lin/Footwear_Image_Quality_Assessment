cd 'X:\Lily\pHD_research\feature_extraction\all_features\wavelet'; %set up working directory
pwd; %check working directory 

%%
%%write a loop to load images in different folders 

%create a vector for folders including images
img_path = {'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\CS_bounding_gray\','X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\HQ_bounding_gray\'};


%% loop through all images each folder
for k = 1:numel(img_path)
% list all tif files in the folder
imgs = dir(fullfile(img_path{k}, '*.tif'));

imgs_count = numel(imgs);
% create two empty array based on the total number of images in each folder
fishscore_g = zeros(imgs_count,1);
fishscore_l = zeros(imgs_count,1);
%%

% ****Open a file to write to:
fid = fopen('wavelet_fish.csv', 'a');
fprintf(fid, 'filename , fishscore_g , fishscore_l \n');

for i=1:imgs_count
tic; %start stopwatch timer  
img = imread(strcat(img_path{k},imgs(i).name));

% compute fish global score
fish_g = fish(img);
% store the global score in the empty array
fishscore_g(i) = fish_g;

% compute fish local score
fish_l = fish_bb(img);
% store the local score in the empty array
fishscore_l(i)= fish_l;

% modify image filenames for the output
if k==1
    img_name = extractBefore(imgs(i).name,"_segmented_bounding.tif");
else
    img_name = extractBefore(imgs(i).name,"_EIGEN_Reg_segmented_bounding.tif");
end

% ****Write the scores to file line by line:
fprintf(fid, '%s , %f , %f \n', img_name, fishscore_g(i), fishscore_l(i));

fprintf('This is %s\n', img_name);
fprintf('This is the FISH score:   %f\n', fish_g);
fprintf('This is the FISHBB score: %f\n', fish_l);
fprintf('Elapsed time:   %.2f seconds\n', toc);

fprintf('=== Process: %d/%d ===\n', i, imgs_count);

%results = [imgs(i).name fish_g fish_l];
%writematrix(results, 'imgqualinfogb.csv', 'append');
%fprintf('====== Wrote info file ======\n');


end

end
% ****Close the file
fclose(fid);
fprintf('====== Wrote info file ======\n');


%toc;