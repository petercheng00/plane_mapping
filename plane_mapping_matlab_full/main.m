addpath Peter
% Run this on all the big planes

% The first argument is the plane number, assuming you start counting at 1
% In the files they are listed as planes 0,1,2,3, etc. I count 1,2,3 etc.

% The second argument is 1 if you want to generate the images and SIFT features
% from scratch, and zero if you want to use the previously generated images and
% SIFT features. If you run it with '1', from that point forward you can run it
% with '0' and it will skip all the slow stuff. The images and SIFT features
% are saved in the plane folder as 'distmats.mat'

%name of folder in matlab directory
global modelName
global imgPath
global inputPath
global modelPath
global outputPath
global mapFile
global prePath
global textureStyle
global fillHoles

%MODIFY THESE VALUES%%%%%%%%%%%%%%%%%%%%%%%%%%%


modelName = 'nov222011_set1_leftRight_kims_v2';
%name of folder in E drive
%imgPath = 'E:\projects\indoormapping\data\2011825-3\images';
imgPath = 'E:\projects\indoormapping\data\20111122-1\images';

prePath = 'C:\\Users\\pcheng\\Documents\\modeling_MA\\plane_mapping_matlab_full';

textureStyle = 'dynprog';
fillHoles = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inputPath = strcat('models/', modelName, '/input_files');
outputPath = strcat('models/', modelName, '/output');
modelPath = strcat('models/', modelName, '/input_files/', modelName, '.model');
mapFile = strcat(modelName, '.map');

fid = fopen(modelPath);
modelNumPlanes = fgets(fid);
fclose(fid);
warning off
mkdir(outputPath);
warning on

%write num planes into rpinput file

%planesToTexture = 15:str2double(modelNumPlanes);
planesToTexture = 21;
fid = fopen(mapFile, 'w');
fprintf(fid, strcat(num2str(modelNumPlanes), '\n'));
fclose(fid);
prevLoaded = 0;
for planeInd = 1:size(planesToTexture, 2)
    if (planesToTexture(planeInd) ~= prevLoaded + 1)
        fid = fopen(mapFile, 'a');
        fprintf(fid, ['SKIP_TO ', num2str(planesToTexture(planeInd) - 1), '\n']);
        fclose(fid);
    end
    disp(['loading plane ', num2str(planesToTexture(planeInd))])
    loadPlane(planesToTexture(planeInd))
    prevLoaded = planesToTexture(planeInd);
end
if size(planesToTexture) < str2num(modelNumPlanes)
    fid = fopen(mapFile, 'a');
    fprintf(fid, 'SKIP_TO END\n');
    fclose(fid);
end
%25 to 72
