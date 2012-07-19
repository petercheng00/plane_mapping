function fillCFWalls3c(th, th2)

%This functions takes a *.model file as input and returns a *.model file
%with all walls touching  ceilings

%th- distance threshold between a celilng/floor and a wall (in Z direction)
%th2 -distance threshold to smooth edges of ceiling floor following walls
%Some vertices of celing/floor replaced by vertices of walls
%for models with more than 1 story too
%for ceilings with different heights


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
%Divide planes into two sets
CF=[];
walls=[];

for cplane=1:1:tot_planes

    if ((abs(planes.p(cplane).eq(1))==0) && (abs(planes.p(cplane).eq(2))==0)) %A ceiling or floor
        CF=[CF; cplane];
        toRemove.p(cplane).point(1:planes.p(cplane).npoints)=0; %points that have been checked      
        newValues.p(cplane).point(1:planes.p(cplane).npoints)=0; %new points values  
    end

    if (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(2))) && (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(3))) %A wall with stron X-normal component
        walls=[walls; cplane];
    end

    if (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(1))) && (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(3))) %A wall with stron X-normal component
        walls=[walls; cplane];
    end

end




%Pair up walls with CF if they are close enough to each other
for wall=1:1:size(walls,1)
    %size(walls,1)
    
    
    wall;
    cplane=walls(wall);
    
    Xcoor=planes.p(cplane).x;
    Ycoor=planes.p(cplane).y;
    Zcoor=planes.p(cplane).z;
    minZ=min(Zcoor);
    maxZ=max(Zcoor);
    maxX=max(Xcoor);
    minX=min(Xcoor);
    maxY=max(Ycoor);
    minY=min(Ycoor);

    %initially mark the wall as unmatched
    matchedCeiling=0;
    matchedFloor=0;
    
    for p=1:1:size(CF,1)

        %size(CF,1)
        candidates=[];
        p;
        cplaneCF=CF(p);
        atZ=planes.p(cplaneCF).z(1);
        
        
       %Calculate range of wall in X and Y
        rangeX=abs(maxX-minX);
        rangeY=abs(maxY-minY);

        if (maxZ<=(atZ+th) && maxZ>=(atZ-th)) 
            
            %wall
            %disp('paired up with ceiling');
            %p

            if (matchedCeiling==0) % wall un-matched with a ceiling
                %Make coordinates in z of the wall touch the ceiling
                pointer=find(Zcoor==maxZ);
                a=planes.p(cplane).eq(1);
                b=planes.p(cplane).eq(2);
                c=planes.p(cplane).eq(3);
                d=planes.p(cplane).eq(4);

                if rangeY>rangeX
                    pointerMinY=find(planes.p(cplane).y(pointer)==minY);
                    pointerMaxY=find(planes.p(cplane).y(pointer)==maxY);

                    planes.p(cplane).x(pointer(pointerMinY))=(-d-(c*atZ)-(b*minY))/a;
                    planes.p(cplane).x(pointer(pointerMaxY))=(-d-(c*atZ)-(b*maxY))/a;
                end

                if rangeX>=rangeY
                    pointerMinX=find(planes.p(cplane).x(pointer)==minX);
                    pointerMaxX=find(planes.p(cplane).x(pointer)==maxX);

                    planes.p(cplane).y(pointer(pointerMinX))=(-d-(c*atZ)-(a*minX))/b;
                    planes.p(cplane).y(pointer(pointerMaxX))=(-d-(c*atZ)-(a*maxX))/b;
                end

                planes.p(cplane).z(pointer)=atZ;
            end
               
            %get X,Y coordinates associated with maxZ
            %disp('Wall and ceiling');
            %wall
            %p
            XYsAt=find(Zcoor==maxZ);
            candidates=[];
            
            if rangeY>rangeX           
                Yc=Ycoor(XYsAt);
                Xc=Xcoor(XYsAt);
                minY=min(Yc);
                maxY=max(Yc);
                for i=1:1:planes.p(cplaneCF).npoints
                    %if  toRemove.p(cplaneCF).point(i)==0 %if point has not been checked
                        if (planes.p(cplaneCF).y(i)>=minY) && (planes.p(cplaneCF).y(i)<=maxY);
                            candidates=[candidates, i];
                        end
                    %end
                end

            end%!!!!!!!!!!

            if rangeX>=rangeY
                Yc=Ycoor(XYsAt);
                Xc=Xcoor(XYsAt);
                minX=min(Xc);
                maxX=max(Xc);
                for i=1:1:planes.p(cplaneCF).npoints
                   % if  toRemove.p(cplaneCF).point(i)==0 %if point has not been checked
                        if (planes.p(cplaneCF).x(i)>=minX) && (planes.p(cplaneCF).x(i)<=maxX);
                            candidates=[candidates, i];
                        end
                    %end
                end

            end%!!!!!!!!!!
         end


        if (minZ<=(atZ+th) && minZ>=(atZ-th)) %&& matchedFloor==0 % wall matched witha a floor
            matchedFloor=1;
            %wall
            %disp('paired up with floor');
            %p
            
            %Make coordinates in z of the wall touch the floor
            pointer=find(Zcoor==minZ);
            
            a=planes.p(cplane).eq(1);
            b=planes.p(cplane).eq(2);
            c=planes.p(cplane).eq(3);
            d=planes.p(cplane).eq(4);
            
            if rangeY>rangeX
                pointerMinY=find(planes.p(cplane).y(pointer)==minY);
                pointerMaxY=find(planes.p(cplane).y(pointer)==maxY);
                
                planes.p(cplane).x(pointer(pointerMinY))=(-d-(c*atZ)-(b*minY))/a;
                planes.p(cplane).x(pointer(pointerMaxY))=(-d-(c*atZ)-(b*maxY))/a;                
            end
            
             if rangeX>=rangeY
                pointerMinX=find(planes.p(cplane).x(pointer)==minX);
                pointerMaxX=find(planes.p(cplane).x(pointer)==maxX);
                
                planes.p(cplane).y(pointer(pointerMinX))=(-d-(c*atZ)-(a*minX))/b;
                planes.p(cplane).y(pointer(pointerMaxX))=(-d-(c*atZ)-(a*maxX))/b;                
             end
%             
            planes.p(cplane).z(pointer)=atZ;
            
            %get X,Y coordinates associated with minZ
            %disp('Wall and floor');
            %wall
            %p
            XYsAt=find(Zcoor==minZ);
            candidates=[];
           
            if rangeY>rangeX
                %calcualte min and max value of Y coordinates at minZ
                Yc=Ycoor(XYsAt);
                Xc=Xcoor(XYsAt);
                minY=min(Yc);
                maxY=max(Yc);
                for i=1:1:planes.p(cplaneCF).npoints
                    %if  toRemove.p(cplaneCF).point(i)==0 %if point has not been checked
                        if (planes.p(cplaneCF).y(i)>=minY) && (planes.p(cplaneCF).y(i)<=maxY);
                            candidates=[candidates, i];
                        end
                    %end
                end
            end

            if rangeX>=rangeY
                Yc=Ycoor(XYsAt);
                Xc=Xcoor(XYsAt);
                minX=min(Xc);
                maxX=max(Xc);
                for i=1:1:planes.p(cplaneCF).npoints
                    %if  toRemove.p(cplaneCF).point(i)==0 %if point has not been checked
                        if (planes.p(cplaneCF).x(i)>=minX) && (planes.p(cplaneCF).x(i)<=maxX);
                            candidates=[candidates, i];
                        end
                   % end
                end
            end
        end
        
         if size(candidates,2)==0
             continue;
         end
         
        %Check if points in candidates may be separated in various
        %sets
        previous=candidates(1);
        stop=[];
        for i=2:1:size(candidates,2)
            if (abs(candidates(i)-previous)>=10);
                stop=[stop, i];
            end
            previous=candidates(i);
        end



        %get distance for each point to equation line
        [m,b]=line_param(planes.p(cplane).x(XYsAt(1)),planes.p(cplane).x(XYsAt(2)),planes.p(cplane).y(XYsAt(1)),planes.p(cplane).y(XYsAt(2)));
        wRange=[];
        
        for i=1:1:size(candidates,2)
            A=m;
            B=-1;
            C=b;

            d=abs(( A*planes.p(cplaneCF).x(candidates(i))) + (B*planes.p(cplaneCF).y(candidates(i))) + C)/sqrt((A^2)+(B^2));
            if d<=th2
                wRange=[wRange, candidates(i)];
            end
        end


        %Check the largest set that can be replaced by two points
        totPtsSet=[];
        maxSet=0;
        minS=0;
        maxS=0;
        if size(stop,2)>0
            for i=1:1:size(stop,2)+1
                count=0;
                if (i==1)
                    minS=candidates(1);
                    maxS=candidates(stop(1)-1);
                end
                if (i>1 && i <size(stop,2)+1)
                    minS=candidates(stop(i-1));
                    maxS=candidates(stop(i)-1);
                end
                if (i==size(stop,2)+1)
                    minS=candidates(stop(size(stop,2)));
                    maxS=candidates(size(candidates,2));
                end
                for k=1:1:size(wRange,2)
                    if (wRange(k)>=minS) && (wRange(k)<=maxS)
                        count=count+1;
                    end
                end
                totPtsSet(i)=count;
            end

            %Pick the set with the most no. of points
            maxSet=find(totPtsSet==max(totPtsSet));
        end

        if size(stop,2)==0 && size(candidates,2)>0
            minS=candidates(1);
            maxS=candidates(size(candidates,2));
            maxSet=1;
        end

        finalCand=[];
        if (maxSet==1 & size(stop,2)==0)
            finalCand=candidates;

        end

        if (maxSet==1 &  size(stop,2)>0)
            finalCand=candidates(1:(stop(1)-1));

        end
        if (maxSet>1 & maxSet <size(stop,2)+1)
            i=maxSet;
            finalCand=candidates((stop(i-1)):(stop(i)-1));
        end
        if (maxSet==size(stop,2)+1 & size(stop,2)>0)
            i=maxSet;
            finalCand=candidates((stop(size(stop,2))):(size(candidates,2)));
        end

        %candidates
        %finalCand
        %Get the final candidates points
        metDist=[];
        if size(finalCand>0)
            for i=1:1:size(wRange,2)
                if wRange(i)>=finalCand(1) && wRange(i)<=finalCand(size(finalCand,2))
                    metDist=[metDist, wRange(i)];
                end
            end
        end

        if size(metDist,2)>2
            
            %at least 2 points are within distance to this wall, so mark
            %the wall as matched
            matchedCeiling=1;
            
            
            minPt=min(metDist);
            maxPt=max(metDist);

            %Replace candidates with two points (note: should be the
            %pojection of the points into line
            i=minPt;
            k=maxPt;
            
            pi=[planes.p(cplaneCF).x(i)  planes.p(cplaneCF).y(i) 0];%The wo vertices of the ceiling/floor closest to wall
            pk=[planes.p(cplaneCF).x(k)  planes.p(cplaneCF).y(k) 0];

            p1=[Xc(1) Yc(1) 0]; %the 2 vertices of the wall closest to Ceiling/floor
            p2=[Xc(2) Yc(2) 0];
            
            %distance from pi,pk to p1
            dp1_pi = getDistance(p1,pi);
            dp1_pk = getDistance(p1,pk);
            
            if (dp1_pi<=dp1_pk)
                newPti = p1;
                newPtk = p2;           
            else
                newPti = p2;
                newPtk = p1;    
            end
            

            toRemove.p(cplaneCF).point(i)=2; %points already checked
            toRemove.p(cplaneCF).point(k)=2; %points already checked
            toRemove.p(cplaneCF).point((i+1):(k-1))=1; %points that need to be removed
            
            newValues.p(cplaneCF).x(i)=newPti(1); %new projected points
            newValues.p(cplaneCF).y(i)=newPti(2);
            newValues.p(cplaneCF).x(k)=newPtk(1);
            newValues.p(cplaneCF).y(k)=newPtk(2);


            %Update No. of points of plane
            %planes.p(cplaneCF).npoints=size(planes.p(cplaneCF).x,2);
        
        end
        
    end
end


for nPlane=1:1:size(CF,1)
    cplaneCF=CF(nPlane);
    planes2.p(cplaneCF).x=[];
    planes2.p(cplaneCF).y=[];
    planes2.p(cplaneCF).z=[];
    
    for nV=1:1:size(newValues.p(cplaneCF).point,2)
        if (toRemove.p(cplaneCF).point(nV)==2)
            planes2.p(cplaneCF).x = [planes2.p(cplaneCF).x, newValues.p(cplaneCF).x(nV)];
            planes2.p(cplaneCF).y = [planes2.p(cplaneCF).y, newValues.p(cplaneCF).y(nV)];
            planes2.p(cplaneCF).z=  [planes2.p(cplaneCF).z, planes.p(cplaneCF).z(nV)];
        end
        if  (toRemove.p(cplaneCF).point(nV)==0)
            planes2.p(cplaneCF).x = [planes2.p(cplaneCF).x, planes.p(cplaneCF).x(nV)];
            planes2.p(cplaneCF).y = [planes2.p(cplaneCF).y, planes.p(cplaneCF).y(nV)];
            planes2.p(cplaneCF).z = [planes2.p(cplaneCF).z, planes.p(cplaneCF).z(nV)];
        end
    end
     planes.p(cplaneCF).npoints=size(planes2.p(cplaneCF).x,2); 
     planes.p(cplaneCF).x = planes2.p(cplaneCF).x;
     planes.p(cplaneCF).y = planes2.p(cplaneCF).y;
     planes.p(cplaneCF).z = planes2.p(cplaneCF).z;
end
    
    fid2 = fopen([pathname  'FCF_' filename ], 'wt');
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
end



