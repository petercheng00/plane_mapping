addpath models

%name of folder in matlab directory
global modelName
global imgPath
global inputPath
global modelPath
global mapFile
global prePath

%MODIFY THESE VALUES%%%%%%%%%%%%%%%%%%%%%%%%%%%
runParallel = false;

%modelName = 'pier15-2_adjusted';
modelName = 'aug252011_all_set3_kims_v0';
%modelName = 'nov222011_set1_leftRight_kims_v2_heightsFixed_floorSplit';
%name of folder in E drive
%imgPath = 'F:\projects\indoormapping\data\Pier15\20120504-2\images';
imgPath = 'E:\projects\indoormapping\data\20110825-3\images';
%imgPath = 'E:\projects\indoormapping\data\20111122-1\images';

prePath = 'C:\\Users\\pcheng\\Documents\\plane_mapping\\plane_mapping_matlab_full';
%prePath = 'F:\projects\plane_mapping\plane_mapping_matlab_full';

textureStyle = 'dynprogsplit_plane';
%texture extrapolation
fillHoles = false;

%use saved intermediate images if available
usePreProcessed = false;

%0 for all
planesToTexture = [163,177];

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
if planesToTexture == 0
    planesToTexture = 1:str2double(modelNumPlanes);
end

fid = fopen(mapFile, 'w');
fprintf(fid, strcat(num2str(modelNumPlanes), '\n'));
fclose(fid);

planes = loadPlanes(inputPath, modelPath, outputPath, mapFile, prePath, textureStyle);
if size(planesToTexture) < str2double(modelNumPlanes)
    fid = fopen(mapFile, 'a');
    fprintf(fid, 'SKIP_TO END\n');
    fclose(fid);
end
if runParallel
    disp(['texturing planes: ', num2str(planesToTexture)]);
    matlabpool
    parfor planeInd = 1:size(planesToTexture, 2)
        planeNum = planesToTexture(planeInd);
        texturePlane(planes,planeNum, outputPath, textureStyle, fillHoles, usePreProcessed);
        %hopefully matlab frees this memory
        %planes(planeNum).images = [];
    end
    clear
    matlabpool close
else
    for planeInd = 1:size(planesToTexture, 2)
        planeNum = planesToTexture(planeInd);
        disp(['texturing planes ', num2str(planeNum)]);
        texturePlane(planes,planeNum, outputPath, textureStyle, fillHoles, usePreProcessed);
        %hopefully matlab frees this memory
        %planes(planeNum).images = [];
    end
end