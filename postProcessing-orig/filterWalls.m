function filterWalls(threshold)
%20100504_set3_3scan_3cam_ibr (may data set)
[filename, pathname] = uigetfile('*.model', 'OPEN *.model file', 'C:\cygwin\tmp\pcl-0.9.0\bin');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);
dValue=inf; floorAt=inf; ceilingAt=inf;

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;
wallDelPoints=[];
range=0.7;
w=1;

height=2.5; %default height (2.5 m)


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
        
            difX=abs(planes.p(cplane).x(1)-planes.p(cplane).x(3));  
             difY=abs(planes.p(cplane).y(1)-planes.p(cplane).y(3)); 
             difZ=abs(planes.p(cplane).z(1)-planes.p(cplane).z(3)); 
             
%              if difX>difY %%check if we have a wall wide enough to use
%                  if difX>=0.5 && difZ>=height*0.60
%                     wall=1;
%                  end
%              else
%                  if difY>=0.5 && difZ>=height*0.60
                     wall=1;
%                  end
%              end
        
             if wall==1
                walls(w).normal=planes.p(cplane).eq';
                walls(w).bounding_box(1)=planes.p(cplane).x(1);
                walls(w).bounding_box(2)=planes.p(cplane).y(1);
                walls(w).bounding_box(3)=planes.p(cplane).z(1);
                walls(w).bounding_box(4)=planes.p(cplane).x(2);
                walls(w).bounding_box(5)=planes.p(cplane).y(2);
                walls(w).bounding_box(6)=planes.p(cplane).z(2);
                walls(w).bounding_box(7)=planes.p(cplane).x(3);
                walls(w).bounding_box(8)=planes.p(cplane).y(3);
                walls(w).bounding_box(9)=planes.p(cplane).z(3);
                walls(w).bounding_box(10)=planes.p(cplane).x(4);
                walls(w).bounding_box(11)=planes.p(cplane).y(4);
                walls(w).bounding_box(12)=planes.p(cplane).z(4);
                w=w+1;
             end

    end
           
end
    


%%Smooth del. points of ceiling/floor
cplane2=1;
for cplane=1:1:tot_planes

    if planes.p(cplane).npoints>4 %Check if we have the floor or ceiling
            
           %[Xcoord, Ycoord]=adjustVertexCF(walls, planes.p(cplane).x, planes.p(cplane).y, 0.5);
           %Zcoord(1:size(Xcoord,2))=planes.p(cplane).z(1);
   
           
    
           planes2.p(cplane2).npoints = planes.p(cplane).npoints;%size(Xcoord,2);
           planes2.p(cplane2).eq = planes.p(cplane).eq;
           planes2.p(cplane2).x = planes.p(cplane).x;%Xcoord;
           planes2.p(cplane2).y = planes.p(cplane).y;%Ycoord;
           planes2.p(cplane2).z = planes.p(cplane).z;%Zcoord;
           cplane2=cplane2+1;

    end    
        
    if  planes.p(cplane).npoints==4 %Check if we have a wall wide and tall enough to keep
             difX=abs(planes.p(cplane).x(1)-planes.p(cplane).x(4));  
             difY=abs(planes.p(cplane).y(1)-planes.p(cplane).y(4));  
             difZ=abs(planes.p(cplane).z(1)-planes.p(cplane).z(3)); 
             width=sqrt(difX^2+difY^2);
             
             %if difX>difY
                 if width>=0.5 && difZ>=0.6*height
                     planes2.p(cplane2)=planes.p(cplane);
                     cplane2=cplane2+1;
                % end
             %else
                  %if difY>=0.7 && difZ>=0.6*height
                      %planes2.p(cplane2)=planes.p(cplane);
                      %cplane2=cplane2+1;
                  %end
              end
                 
    end
    


end

planes2.tot=cplane2-1;
    
%Save the new data in a *.model file

%[outfilename outpathname]=uiputfile('*.model', 'SAVE as *.model file', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
%fid2 = fopen([outpathname outfilename], 'wt');
fid2 = fopen([pathname 'FW_' filename ], 'wt');
fprintf(fid, '%i\n',planes2.tot); %Total number of planes
pointer=2;
tot_planes=planes2.tot;

for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planes2.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes2.p(cplane).eq(1,1), planes2.p(cplane).eq(2,1),planes2.p(cplane).eq(3,1),planes2.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes2.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes2.p(cplane).x(cpoint), planes2.p(cplane).y(cpoint),planes2.p(cplane).z(cpoint));
    end
    
end

fclose(fid2);

%%Plot the planes
figure;
planes=[];

fid = fopen([pathname 'FW_' filename ]);
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

        vert=[planes.p(cplane).x', planes.p(cplane).y',planes.p(cplane).z']; 
        fac=[1:1:planes.p(cplane).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[(cplane/(tot_planes*2)) (cplane/tot_planes) (cplane/tot_planes)]); hold on;
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    

end
end

