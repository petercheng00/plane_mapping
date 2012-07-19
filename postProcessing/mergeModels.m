function mergeModels( )
%Merges two models into a single *.model file


[filename, pathname] = uigetfile('*.model', 'Select first model (*.model)', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
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

%%%%%%%%%%%%%%

[filename2, pathname2] = uigetfile('*.model', 'Select second model (*.model)', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
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


%%%%%%%%%%%%%



fid2 = fopen([pathname  'FINAL_' filename ], 'wt');
fprintf(fid, '%i\n',planesR.tot+planesE.tot); %Total number of planes
pointer=2;
tot_planes=planesR.tot;

for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planesR.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planesR.p(cplane).eq(1,1), planesR.p(cplane).eq(2,1),planesR.p(cplane).eq(3,1),planesR.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planesR.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planesR.p(cplane).x(cpoint), planesR.p(cplane).y(cpoint), planesR.p(cplane).z(cpoint));
    end   
end

tot_planes=planesE.tot;
for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planesE.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planesE.p(cplane).eq(1,1), planesE.p(cplane).eq(2,1),planesE.p(cplane).eq(3,1),planesE.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planesE.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planesE.p(cplane).x(cpoint), planesE.p(cplane).y(cpoint), planesE.p(cplane).z(cpoint));
    end   
end

fclose(fid2);

end

    
   