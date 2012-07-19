function fillCorners2(th, th2)

%This functions takes a *.model file as input and returns a *.model file
%with all walls touching each other at the corners

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
%Divide walls into two sets 
wallsX=[];
wallsY=[];
for cplane=1:1:tot_planes
    
    if (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(2))) && (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(3))) %A wall with stron X-normal component
        wallsX=[wallsX; cplane];
    end
    
    if (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(1))) && (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(3))) %A wall with stron Y-normal component
        wallsY=[wallsY; cplane];
    end

end


%Pair up wallsX with wallsY if they are close enough to each other
for wall=1:1:size(wallsX,1)
    wall;

    
    for wallp=1:1:size(wallsY,1)
        wallp;
        
        cplane=wallsX(wall);
        Xcoor=planes.p(cplane).x;
        Ycoor=planes.p(cplane).y;
        Zcoor=planes.p(cplane).z;
    

        minX=min(Xcoor);
        maxX=max(Xcoor);
        minY=min(Ycoor);
        maxY=max(Ycoor);
        minZ=min(Zcoor);
        maxZ=max(Zcoor);
        
        cplaneY=wallsY(wallp);
        Xcoor2=planes.p(cplaneY).x;
        Ycoor2=planes.p(cplaneY).y;
        Zcoor2=planes.p(cplaneY).z;
        minX2=min(Xcoor2);
        maxX2=max(Xcoor2);
        minY2=min(Ycoor2);
        maxY2=max(Ycoor2);
        minZ2=min(Zcoor2);
        maxZ2=max(Zcoor2);
        
        if maxZ2>maxZ+th2 || minZ2<minZ-th2
            continue;
        end
        
        %check if wall(x) is close to wallp(y) using Y axis (rangeY of
        %cplane grater than rangeX)
        
        pointer=find(planes.p(cplane).y==minY);
        p1=[planes.p(cplane).x(pointer(1)), minY];
            
        pointer=find(planes.p(cplane).y==maxY);
        p2=[planes.p(cplane).x(pointer(1)), maxY];
        
        pointer=find(planes.p(cplaneY).y==minY2);
        p3=[planes.p(cplaneY).x(pointer(1)), minY2];
            
        pointer=find(planes.p(cplaneY).y==maxY2);
        p4=[planes.p(cplaneY).x(pointer(1)), maxY2];
        
        %check distances between points
        
        dp1p3 = sqrt( (p1(1)-p3(1))^2 + (p1(2)-p3(2))^2 );

        dp1p4 = sqrt( (p1(1)-p4(1))^2 + (p1(2)-p4(2))^2 );
        
        dp2p3 = sqrt( (p2(1)-p3(1))^2 + (p2(2)-p3(2))^2 );
        
        dp2p4 = sqrt( (p2(1)-p4(1))^2 + (p2(2)-p4(2))^2 );
        
        distances=[dp1p3 dp1p4 dp2p3 dp2p4];
        
        if min(distances)<=th
            %two wall have been matched
            cplane
            cplaneY
            pD=find(distances==min(distances)); 
            
            %Find line where the two planes meet
       
            [p1 p2]=twoPointsLine(planes.p(cplane).eq, planes.p(cplaneY).eq);
            
             if (pD==1)
                 val1=minY;
                 val2=minY2;
             end
             
              if (pD==2)
                 val1=minY;
                 val2=maxY2;
              end
             
               if (pD==3)
                 val1=maxY;
                 val2=minY2;
               end
             
             if (pD==4)
                 val1=maxY;
                 val2=maxY2;
             end
            
                pointer = find(planes.p(cplane).y==val1); % points with same maxY values in cplane
                
                for k=1:1:size(pointer,2)
                    p=[planes.p(cplane).x(pointer(k)) planes.p(cplane).y(pointer(k)) planes.p(cplane).z(pointer(k))];
                    projPt = point2Line3D(p,p1,p2);
                    %replace points with porjected ones
                    planes.p(cplane).x(pointer(k))=projPt(1);
                    planes.p(cplane).y(pointer(k))=projPt(2);
                    if projPt(3)~= planes.p(cplane).z(pointer(k))
                        disp('Adjusting z');
                    end
                        %planes.p(cplane).z(pointer(k))=projPt(3);
                end
                
                pointer=find(planes.p(cplaneY).y==val2); % points with same maxY2 values in cplaneY
                valX= planes.p(cplaneY).x(pointer(1)); %get the correspondig value in X
                pointer = find(planes.p(cplaneY).x==valX); % points with same valX values in cplaneY
                
                 for k=1:1:size(pointer,2)
                    p=[planes.p(cplaneY).x(pointer(k)) planes.p(cplaneY).y(pointer(k)) planes.p(cplaneY).z(pointer(k))];
                    projPt = point2Line3D(p,p1,p2);
                    %replace points with porjected ones
                    planes.p(cplaneY).x(pointer(k))=projPt(1);
                    planes.p(cplaneY).y(pointer(k))=projPt(2);
                     if projPt(3)~= planes.p(cplaneY).z(pointer(k))
                        disp('Adjusting z');
                    end
                        %planes.p(cplane).z(pointer(k))=projPt(3);
                end
          
        end
    end

end

    

fid2 = fopen([pathname  'F_' filename ], 'wt');
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

figure;

for cplane=1:1:tot_planes


        vert=[planes.p(cplane).x', planes.p(cplane).y',planes.p(cplane).z']; 
        fac=[1:1:planes.p(cplane).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[(cplane/(tot_planes*2)) (cplane/tot_planes) (cplane/tot_planes)]); hold on;
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    

end

    
   