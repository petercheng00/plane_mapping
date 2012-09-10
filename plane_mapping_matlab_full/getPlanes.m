function getPlanes( )

%Plot planes in *model file

%file='\\arbadil\modeling_data_new\20100825_set3\out_nodes_ive\plane\icpimuplannar_mad_results\20100825_set3_3scan_leftcam_noibr.model';
%20100504_set3_1scan_3cam_noibr (may data set)
%close all;
[filename, pathname] = uigetfile('*.model', 'Select *.model file');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;
figure;
counter = 1;
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
    
    
    %plot delimiting points
    %if cplane==9 || cplane==10
    %if planes.p(cplane).npoints>4
        %figure;
        %Plot as a bunch of points on the z plane
        %scatter(planes.p(cplane).x,planes.p(cplane).y);
        
        %Plot the whole plane
        %a = planes.p(cplane).eq(1,1); b = planes.p(cplane).eq(2,1); c = planes.p(cplane).eq(3,1); d = planes.p(cplane).eq(4,1); 
        %[xx,yy,zz] = meshgrid(-5:0.1:5, -5:0.1:5, -2:0.1:2); 
        %isosurface(xx, yy, zz, a*xx+b*yy+c*zz+d, cplane); hold on;
        
        %plot the delimited plane
        %patch('vertices',[0 6 0; 0 9 0; 1 9 0; 0 6 1; 0 9 1; 1 9 1],'faces',[1 2 5 4; 2 3 6 5],'facecolor',[.5 .5 .5])
        %view(3)
        vert=[planes.p(cplane).x', planes.p(cplane).y',planes.p(cplane).z']; 
        fac=[1:1:planes.p(cplane).npoints];
        if (counter > 22)
            patch('vertices', vert,'faces',fac,'facecolor',rand(1,3)); hold on;
            %patch('vertices', vert,'faces',fac,'facecolor',[(cplane/tot_planes*.9) 0.5 (cplane/tot_planes*.7)]); hold on;
                %patch('vertices', vert,'faces',fac,'facecolor',[0 .8 0]); hold on;
        end
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp(counter);
		counter = counter + 1;
        pause    
        %axis([-12 6 -6 26 -1.5 1.8])
    %end
    %end
end
end
    
   