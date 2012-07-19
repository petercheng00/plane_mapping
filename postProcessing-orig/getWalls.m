function getWalls(minZ, maxZ, story)

%Get walls associated with a pair of ceiling/floor
%minZ - minimum value of z 
%maxZ- maximum value of z
%story - index of the floor to be extracted


[filename, pathname] = uigetfile('*.model', 'Select *.model file', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;

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

fp=1;
for cplane=1:1:tot_planes
Zcoord=planes.p(cplane).z;

if min(Zcoord)>=minZ && max(Zcoord)<=maxZ
    planes2.p(fp)=planes.p(cplane);
    fp=fp+1;
end
    
end
planes2.tot=size(planes2.p,2);

%Save walls
fid2 = fopen([pathname  'Story_' num2str(story) '_' filename ], 'wt');
fprintf(fid2, '%i\n',planes2.tot); %Total number of planes
pointer=2;
tot_planes=planes2.tot;

for cplane=1:1:tot_planes

    fprintf(fid2, '%i\n',planes2.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid2, '%f %f %f %f\n', planes2.p(cplane).eq(1,1), planes2.p(cplane).eq(2,1),planes2.p(cplane).eq(3,1),planes2.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes2.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid2, '%f %f %f\n',planes2.p(cplane).x(cpoint), planes2.p(cplane).y(cpoint),planes2.p(cplane).z(cpoint));
    end

end
fclose(fid2);

end
    
   