function generateInputFiles()
[sortedAtlasFile, sortedAtlasPath] = uigetfile('*.txt', 'Select SortedAtlasImages file');
[imageDir] = uigetdir('E:\projects\indoormapping\data', 'Select images directory');
safid = fopen(strcat(sortedAtlasPath, sortedAtlasFile));
outDir = sortedAtlasPath;
warning off;
delete(strcat(outDir, 'masks.txt'), strcat(outDir, 'filenames.txt'), strcat(outDir, 'imgplanes.txt'), strcat(outDir, 'translations.txt'), strcat(outDir, 'rotations.txt'))
warning on;
masksfid = fopen(strcat(outDir, 'masks.txt'), 'W');
fileNamesfid = fopen(strcat(outDir, 'filenames.txt'), 'W');
imgPlanesfid = fopen(strcat(outDir, 'imgplanes.txt'), 'W');
translationsfid = fopen(strcat(outDir, 'translations.txt'), 'W');
rotationsfid = fopen(strcat(outDir, 'rotations.txt'), 'W');

firstLine = fgets(safid);
while ischar(firstLine)
    index = strfind(firstLine, '_');
    index = index(end);
    maskLine = firstLine(1:index);
    maskLine = strcat(imageDir, '/', maskLine);
    maskLine = strcat(strrep(maskLine, '\', '/'), 'Mask.bmp\r\n');
    fprintf(masksfid, maskLine);
    
    index = strfind(firstLine, ' ');
    index = index(1);
    imagePath = strcat(imageDir, '/', firstLine(1:index));
    imagePath = strcat(strrep(imagePath, '\', '/'), '\r\n');
    fprintf(fileNamesfid, imagePath);
    
    index = strfind(firstLine, ' ');
    index = index(end);
    fprintf(imgPlanesfid, strcat(firstLine(index+1:end), '\r\n'));
    
    transLine = fgets(safid);
    transLine = transLine(3:(end-4));
    fprintf(translationsfid, strcat(transLine, '\r\n'));
    
    rotLine = fgets(safid);
    rotLine = rotLine(3:(end-4));
    fprintf(rotationsfid, strcat(rotLine, '\r\n'));
    
    %this is hardcoded elsewhere
    fgets(safid);
    fgets(safid);
    fgets(safid);
    firstLine = fgets(safid);
end

fclose(safid);
fclose(masksfid);
fclose(fileNamesfid);
fclose(imgPlanesfid);
fclose(rotationsfid);
fclose(translationsfid);
end

