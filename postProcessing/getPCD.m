function getPCD()

[filename, pathname] = uigetfile('*.pcd', 'Select *.pcd file', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

figure;
view(3)

hold on;

cp=1;
for p=1:1:(size(A,1)/3)
    scatter3(A(cp,1), A(cp+1,1), A(cp+2,1), [25], [0 0 1], 'filled'); %[25] for walls
    cp=cp+3;
end
 daspect([1 1 1]);
 grid on;
end