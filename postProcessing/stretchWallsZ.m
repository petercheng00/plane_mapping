function stretchWallsZ(threshold)
%20100504_set3_3scan_3cam_ibr (may data set)
[filename, pathname] = uigetfile('*.model', 'OPEN *.model file', 'C:\cygwin\tmp\pcl-0.9.0\bin');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);
dValue=inf; floorAt=inf; ceilingAt=inf;

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;

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
    
    %%%%%%%%%%%%%
    if planes.p(cplane).npoints>4 %Check if we have the floor or ceiling
        new_dValue=(-1*planes.p(cplane).eq(4,1))/planes.p(cplane).eq(3,1);
        if dValue==inf;
            dValue=new_dValue; %Store value of d (plane equation)
        else
            if new_dValue>dValue; % Define position for floor and ceiling
                 ceilingAt=new_dValue;
                 floorAt=dValue;
            else 
                 floorAt=new_dValue;
                 ceilingAt=dValue;
            end
            height=abs(floorAt-ceilingAt);
        end
    end
    %%%%%%%%%%%%%   
    
    
    if planes.p(cplane).npoints<=4 %Check if we have a wall
        maxZ=max(planes.p(cplane).z);
        minZ=min(planes.p(cplane).z);
        difCeiling=abs(maxZ-ceilingAt);
        difFloor=abs(minZ-floorAt);
        
        if (maxZ~=ceilingAt && difCeiling<=((threshold/100)*height)) %if wall does not touch ceiling and the gap is less than threshold (%), then stretch wall
            planes.p(cplane).z( find(planes.p(cplane).z==maxZ) )=ceilingAt;
        end
        
        if (minZ~=floorAt && difFloor<=((threshold/100)*height)) %if wall does not touch floor and the gap is less than threshold (%), then stretch wall
            planes.p(cplane).z( find(planes.p(cplane).z==minZ) )=floorAt;
        end
    end
        
        
end
    
%Save the new data ina *.model file

[outfilename outpathname]=uiputfile('*.model', 'SAVE as *.model file', '\\arbadil\modeling_data_new\');
fid2 = fopen([outpathname outfilename], 'wt');
fprintf(fid, '%i\n',planes.tot); %Total number of planes
pointer=2;
tot_planes=planes.tot;

for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint),planes.p(cplane).z(cpoint));
    end
    
end

fclose(fid2);

end
