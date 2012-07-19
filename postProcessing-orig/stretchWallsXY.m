function stretchWallsXY(threshold)
%20100504_set3_3scan_3cam_ibr (may data set)
 [filename, pathname] = uigetfile('*.model', 'OPEN *.model file', '\\arbadil\modeling_data_new\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);
dValue=inf; floorAt=inf; ceilingAt=inf;

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;
newPlanes=0;

%Get all planes in text file
%Walls are usually defined by 4 points
for cplane=1:1:tot_planes

    planes.p(cplane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;

    planes.p(cplane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;

    cpoint=1;
    for x=1:1:planes.p(cplane).npoints %Get the points delimiting plane
        planes.p(cplane).x(cpoint)=A(pointer,1);
        planes.p(cplane).y(cpoint)=A(pointer+1,1);
        planes.p(cplane).z(cpoint)=A(pointer+2,1);
        cpoint=cpoint+1;
        pointer=pointer+3;
    end
end


for cplane=1:1:tot_planes 
    
    if planes.p(cplane).npoints<=4 %Check if we have a wall
        minX=planes.p(cplane).x(find(planes.p(cplane).x==min(planes.p(cplane).x))); %Get one corner of wall
        Y1=planes.p(cplane).y(find(planes.p(cplane).x==min(planes.p(cplane).x)));
        maxX=planes.p(cplane).x(find(planes.p(cplane).x==max(planes.p(cplane).x))); %Get second corner of wall
        Y2=planes.p(cplane).y(find(planes.p(cplane).x==max(planes.p(cplane).x)));
        minZ=min(planes.p(cplane).z);
        maxZ=max(planes.p(cplane).z);
        minX=minX(1,1); %Remove repeated points
        maxX=maxX(1,1);
        Y1=Y1(1,1);
        Y2=Y2(1,1);
    end
    
    for pl=1:1:tot_planes
        pointer=[];
        if planes.p(pl).npoints<=4 && pl~=cplane %Check for corners of neighboring walls
            pointer=find(planes.p(pl).x>=(minX-threshold) & planes.p(pl).x<=(minX+threshold) &...
               planes.p(pl).y>=(Y1-threshold) & planes.p(pl).y<=(Y1+threshold) &...
                   planes.p(pl).z>=minZ-(.1*abs(minZ)) & planes.p(pl).z<=minZ+(.1*abs(minZ))); %Theoretically, planes have the same minZ value. Just in case this is not true, we check for a small range in Z
               
               pointer2=find(planes.p(pl).x>=(maxX-threshold) & planes.p(pl).x<=(maxX+threshold) &...
               planes.p(pl).y>=(Y2-threshold) & planes.p(pl).y<=(Y2+threshold) &...
                   planes.p(pl).z>=minZ-(.1*abs(minZ)) & planes.p(pl).z<=minZ+(.1*abs(minZ))); %Theoretically, planes have the same minZ value. Just in case this is not true, we check for a small range in Z
           
           if ~isempty(pointer) %If corners found, get the coordinates of the area between corner in wall 1 and corners found
               for a=1:1size(pointer,2);
                   fX=planes.p(pl).x(pointer);
                   fY=planes.p(pl).y(pointer);
                   area=[minX Y1 fX fY minZ maxZ]; %Get the area to check for point data
                   pointdata=pdata(area,cloud_file); %Find if there is any data in the point cloud delimited by area
                   if pointdata
                       newPlanes=newPlanes+1;
                       p=newPlane(minX,fX,Y1,fY,minZ,maxZ); %Extend the plane (or add a new plane) to fill gap
                       planes.p(tot_planes+newPlanes)=p;
                   end
               end
           end
           
           
           if ~isempty(pointer2) %If corners found, get the coordinates of the area between corner in wall 1 and corners found
               for a=1:1size(pointer2,2);
                   fX=planes.p(pl).x(pointer2);
                   fY=planes.p(pl).y(pointer2);
                   area=[maxX Y2 fX fY minZ maxZ];
                   pointdata=pdata(area,cloud_file); %Find if there is any data in the point cloud delimited by area
                   if pointdata
                       newPlanes=newPlanes+1;
                       p=newPlane(minX,fX,Y1,fY,minZ,maxZ); %Extend the plane (or add a new plane) to fill gap
                       planes.p(tot_planes+newPlanes)=p;
                   end
               end
           end
           
        end          
    end
    
end

%Save the new data in a *.model file

[outfilename outpathname]=uiputfile('*.model', 'SAVE as *.model file', '\\arbadil\modeling_data_new\');
fid2 = fopen([outpathname outfilename], 'wt');
fprintf(fid, '%i\n',planes.tot); %Total number of planes
pointer=2;
tot_planes=planes.tot+newPlanes;

for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint),planes.p(cplane).z(cpoint));
    end
    
end

fclose(fid2);

end
