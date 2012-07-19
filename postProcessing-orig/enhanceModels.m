function enhanceModels( )
%Merges two set of walls of the same point cloud, for example walls
%detected using the right scanner and walls detected using the left scanner

%theta - maximum angular distange between two normals (in deg)
%dist - maximum Euclidian distance bewteen centroids (in meters)

[filename, pathname] = uigetfile('*.model', 'Select REFERENCE model (*.model)', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planesR = A(1,1);
pointer=2;
planesR.tot=tot_planesR;

for cplane=1:1:tot_planesR

    planesR.p(cplane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;

    planesR.p(cplane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;

    cpoint=1;
    for x=1:1:planesR.p(cplane).npoints %Get the points delimiting plane
        planesR.p(cplane).x(cpoint)=A(pointer,1);
        planesR.p(cplane).y(cpoint)=A(pointer+1,1);
        planesR.p(cplane).z(cpoint)=A(pointer+2,1);
        cpoint=cpoint+1;
        pointer=pointer+3;
    end
 
end

%Divide walls into two sets 
wallsRX=[];
wallsRY=[];
for cplane=1:1:tot_planesR
    
    if (abs(planesR.p(cplane).eq(1))>abs(planesR.p(cplane).eq(2))) && (abs(planesR.p(cplane).eq(1))>abs(planesR.p(cplane).eq(3))) %A wall with stron X-normal component
        wallsRX=[wallsRX; cplane];
    end
    
    if (abs(planesR.p(cplane).eq(2))>abs(planesR.p(cplane).eq(1))) && (abs(planesR.p(cplane).eq(2))>abs(planesR.p(cplane).eq(3))) %A wall with stron Y-normal component
        wallsRY=[wallsRY; cplane];
    end

end

%%%%%%%%%%%%%%

[filename2, pathname2] = uigetfile('*.model', 'Select model to ENHANCE reference model (*.model)', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname2 filename2]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planesE = A(1,1);
pointer=2;
planesE.tot=tot_planesE;

for cplane=1:1:tot_planesE

    planesE.p(cplane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;

    planesE.p(cplane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;

    cpoint=1;
    for x=1:1:planesE.p(cplane).npoints %Get the points delimiting plane
        planesE.p(cplane).x(cpoint)=A(pointer,1);
        planesE.p(cplane).y(cpoint)=A(pointer+1,1);
        planesE.p(cplane).z(cpoint)=A(pointer+2,1);
        cpoint=cpoint+1;
        pointer=pointer+3;
    end
 
end

%Divide walls into two sets 
wallsEX=[];
wallsEY=[];
for cplane=1:1:tot_planesE
    
    if (abs(planesE.p(cplane).eq(1))>abs(planesE.p(cplane).eq(2))) && (abs(planesE.p(cplane).eq(1))>abs(planesE.p(cplane).eq(3))) %A wall with stron X-normal component
        wallsEX=[wallsEX; cplane];
    end
    
    if (abs(planesE.p(cplane).eq(2))>abs(planesE.p(cplane).eq(1))) && (abs(planesE.p(cplane).eq(2))>abs(planesE.p(cplane).eq(3))) %A wall with stron Y-normal component
        wallsEY=[wallsEY; cplane];
    end

end

%%%%%%%%%%%%%

%For each wall in wallEX calculate the centroid and angular distance with
%each wall in wallRX
for wall=1:1:size(wallsEX,1)
    plane=wallsEX(wall);
    wallsEXMetrics.wall(wall).centroid = getCentroid(planesE.p(plane).x, planesE.p(plane).y, planesE.p(plane).z);
    wallsEXMetrics.wall(wall).extension = getExtension(planesE.p(plane).x, planesE.p(plane).y, planesE.p(plane).z);
    
    for wallp=1:1:size(wallsRX,1)
        cplane=wallsRX(wallp);
        wallsRXMetrics.wall(wallp).centroid = getCentroid(planesR.p(cplane).x, planesR.p(cplane).y, planesR.p(cplane).z);
        wallsRXMetrics.wall(wallp).extension = getExtension(planesR.p(cplane).x, planesR.p(cplane).y, planesR.p(cplane).z);
        
        wallsEXMetrics.wall(wall).distances(wallp) = getDistance( wallsEXMetrics.wall(wall).centroid, wallsRXMetrics.wall(wallp).centroid);
        wallsEXMetrics.wall(wall).angleDist(wallp) = getAngleDist(planesE.p(plane).eq, planesR.p(cplane).eq);
        wallsEXMetrics.wall(wall).overlapVol(wallp) = getOverlappingVol(planesE.p(plane), planesR.p(cplane));
    end
    
    %Select walls based on overlapping volume (those wall that do NOT
    %overlapp with any other wall in planeR, are used to enhance planeR
    
    if sum(wallsEXMetrics.wall(wall).overlapVol)==0
        wallsEXMetrics.wall(wall).toEnhance=1;
    else
        wallsEXMetrics.wall(wall).toEnhance=0;
    end
    
end

%%%%%%%%%%%%%

%For each wall in wallEY calculate the centroid and angular distance with
%each wall in wallRY
for wall=1:1:size(wallsEY,1)
    plane=wallsEY(wall);
    wallsEYMetrics.wall(wall).centroid = getCentroid(planesE.p(plane).x, planesE.p(plane).y, planesE.p(plane).z);
    wallsEYMetrics.wall(wall).extension = getExtension(planesE.p(plane).x, planesE.p(plane).y, planesE.p(plane).z);
    
    for wallp=1:1:size(wallsRY,1)
        cplane=wallsRY(wallp);
        wallsRYMetrics.wall(wallp).centroid = getCentroid(planesR.p(cplane).x, planesR.p(cplane).y, planesR.p(cplane).z);
        wallsRYMetrics.wall(wallp).extension = getExtension(planesR.p(cplane).x, planesR.p(cplane).y, planesR.p(cplane).z);
        
        wallsEYMetrics.wall(wall).distances(wallp) = getDistance( wallsEYMetrics.wall(wall).centroid, wallsRYMetrics.wall(wallp).centroid);
        wallsEYMetrics.wall(wall).angleDist(wallp) = getAngleDist(planesE.p(plane).eq, planesR.p(cplane).eq);
        wallsEYMetrics.wall(wall).overlapVol(wallp) = getOverlappingVol(planesE.p(plane), planesR.p(cplane));
    end
    
     %Select walls based on overlapping volume (those walls that do NOT
    %overlapp with any other wall in planeR, are used to enhance planeR
     if sum(wallsEYMetrics.wall(wall).overlapVol)==0
        wallsEYMetrics.wall(wall).toEnhance=1;
     else
        wallsEYMetrics.wall(wall).toEnhance=0;
    end
end

%Loop over walls in wallsEX and wallsEY and select those used to enhance
%planeR
for wall=1:1:size(wallsEX,1)
     plane=wallsEX(wall);
    if wallsEXMetrics.wall(wall).toEnhance==1
        planesR.tot=planesR.tot+1;
        planesR.p=[planesR.p,  planesE.p(plane)];
    end
end

for wall=1:1:size(wallsEY,1)
     plane=wallsEY(wall);
    if wallsEYMetrics.wall(wall).toEnhance==1
        planesR.tot=planesR.tot+1;
        planesR.p=[planesR.p,  planesE.p(plane)];
    end
end

    

fid2 = fopen([pathname  'M_' filename ], 'wt');
fprintf(fid, '%i\n',planesR.tot); %Total number of planes
pointer=2;
tot_planes=planesR.tot;

for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planesR.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planesR.p(cplane).eq(1,1), planesR.p(cplane).eq(2,1),planesR.p(cplane).eq(3,1),planesR.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planesR.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planesR.p(cplane).x(cpoint), planesR.p(cplane).y(cpoint), planesR.p(cplane).z(cpoint));
    end
    
end

fclose(fid2);

figure;

for cplane=1:1:tot_planes


        vert=[planesR.p(cplane).x', planesR.p(cplane).y',planesR.p(cplane).z']; 
        fac=[1:1:planesR.p(cplane).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[(cplane/(tot_planes*2)) (cplane/tot_planes) (cplane/tot_planes)]); hold on;
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    

end

    
   