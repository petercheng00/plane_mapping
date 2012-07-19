function removeCeilingsOrFloors(floors)

%This functions takes a *.model file as input and returns a *.model file
%with all ceilings (floor=0) or all floors (floor=1) removed. The

%th - threshold to find adjacent walls in X,Y direction
%th2 - threshold to find adjacent walls in Z direction



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

%Identify the tot. no. of ceilings or floors
totCeilings=0;
totFloors=0;
for cplane=1:1:tot_planes

    if ( abs(planes.p(cplane).eq(1)) == 0 && abs(planes.p(cplane).eq(2)) == 0 && planes.p(cplane).eq(3)==1) %A floor
        totFloors=totFloors+1;
    end

    if ( abs(planes.p(cplane).eq(1)) == 0 && abs(planes.p(cplane).eq(2)) == 0 && planes.p(cplane).eq(3)==-1) %A ceiling
        totCeilings=totCeilings+1;
    end

end


if (floors==1)
    fid2 = fopen([pathname  'RF_' filename ], 'wt');
    fprintf(fid2, '%i\n',planes.tot-totFloors); %Total number of planes
    fid3 = fopen([pathname  'FLOORS_' filename ], 'wt');
    fprintf(fid3, '%i\n',totFloors); %Total number of floors
end

if (floors==0)
    fid2 = fopen([pathname  'RC_' filename ], 'wt');
    fprintf(fid2, '%i\n',planes.tot-totCeilings); %Total number of planes
    fid3 = fopen([pathname  'CEILINGS_' filename ], 'wt');
    fprintf(fid3, '%i\n',totCeilings); %Total number of ceilings
end

if (floors==1)
    for cplane=1:1:planes.tot
        if ( abs(planes.p(cplane).eq(1)) == 0 && abs(planes.p(cplane).eq(2)) == 0 && planes.p(cplane).eq(3)==1) %A floor
            
            fprintf(fid3, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
            fprintf(fid3, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

            for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
                fprintf(fid3, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint), planes.p(cplane).z(cpoint));
            end
        end


    end
end

if (floors==0)
    for cplane=1:1:planes.tot
        if ( abs(planes.p(cplane).eq(1)) == 0 && abs(planes.p(cplane).eq(2)) == 0 && planes.p(cplane).eq(3)==-1) %A ceiling
            
            fprintf(fid3, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
            fprintf(fid3, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

            for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
                fprintf(fid3, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint), planes.p(cplane).z(cpoint));
            end
        end


    end
end

for cplane=1:1:planes.tot

    if (floors==1)
        if ( (abs(planes.p(cplane).eq(1)) > 0 || abs(planes.p(cplane).eq(2)) > 0) && abs(planes.p(cplane).eq(3))==0 )%A wall

            fprintf(fid2, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
            fprintf(fid2, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

            for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
                fprintf(fid2, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint), planes.p(cplane).z(cpoint));
            end
        end

        if  ( abs(planes.p(cplane).eq(1)) == 0 && abs(planes.p(cplane).eq(2)) == 0 && planes.p(cplane).eq(3)==-1) %A ceiling

            fprintf(fid2, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
            fprintf(fid2, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

            for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
                fprintf(fid2, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint), planes.p(cplane).z(cpoint));
            end
        end

    end

    if (floors==0)
        if ( (abs(planes.p(cplane).eq(1)) > 0 || abs(planes.p(cplane).eq(2)) > 0) && abs(planes.p(cplane).eq(3))==0 )%A wall

            fprintf(fid2, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
            fprintf(fid2, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

            for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
                fprintf(fid2, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint), planes.p(cplane).z(cpoint));
            end
        end

        if  ( abs(planes.p(cplane).eq(1)) == 0 && abs(planes.p(cplane).eq(2)) == 0 && planes.p(cplane).eq(3)==1) %A floor

            fprintf(fid2, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
            fprintf(fid2, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

            for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
                fprintf(fid2, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint), planes.p(cplane).z(cpoint));
            end
        end

    end


end

fclose(fid2);
fclose(fid3);
end





