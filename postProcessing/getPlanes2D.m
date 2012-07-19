function getPlanes2D( )

%file='\\arbadil\modeling_data_new\20100825_set3\out_nodes_ive\plane\icpimuplannar_mad_results\20100825_set3_3scan_leftcam_noibr.model';
%20100504_set3_1scan_3cam_noibr (may data set)
%close all;
[filename, pathname] = uigetfile('*.model', 'Select *.model file', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;
%figure;

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
    
    

        vert=[planes.p(cplane).x', planes.p(cplane).y'];%,planes.p(cplane).z']; 
        fac=[1:1:planes.p(cplane).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[1 0 0]); hold on;
        view(2); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    

end
end
    
   