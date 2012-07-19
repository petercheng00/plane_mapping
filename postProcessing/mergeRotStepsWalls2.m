function mergeRotStepsWalls2(rot,align)

%Takes as input a model file with walls, ceilings, floors and
%a model file with a single set of steps
%Outputs a model file with adjusted walls, ceiling, and floors, and a model file with adjusted
%steps, The steps are rotated to be aligned with sorrounding walls, if rot=1
%The handrail in staircase is aligned to walls if align=1

%Read model file wirl walls.ceiling and floors
[filename, pathname] = uigetfile('*.model', 'Select *.model file containing walls,ceilings and floors', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
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
fclose('all');

%Divide planes into three sets
wallsX=[ ];
wallsY=[ ];
CF=[ ];
for cplane=1:1:tot_planes

    if (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(2))) && (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(3))) %A wall with stron X-normal component
        wallsX=[wallsX; cplane];
    end

    if (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(1))) && (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(3))) %A wall with stron Y-normal component
        wallsY=[wallsY; cplane];
    end

    if ((abs(planes.p(cplane).eq(1))==0) && (abs(planes.p(cplane).eq(2))==0)) %A ceiling or floor
        CF=[CF; cplane];
    end

end


%Read model file with steps
[filename, pathname] = uigetfile('*.model', 'Select *.model file containing the steps', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes2.tot=tot_planes;


for cplane=1:1:tot_planes

    planes2.p(cplane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;

    planes2.p(cplane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;

    cpoint=1;
    for x=1:1:planes2.p(cplane).npoints %Get the points delimiting plane
        planes2.p(cplane).x(cpoint)=A(pointer,1);
        planes2.p(cplane).y(cpoint)=A(pointer+1,1);
        planes2.p(cplane).z(cpoint)=A(pointer+2,1);



        cpoint=cpoint+1;
        pointer=pointer+3;
    end

    %Calculate the centroid of each plane of the steps
    planes2.p(cplane).centroid= getCentroid(planes2.p(cplane).x, planes2.p(cplane).y, planes2.p(cplane).z);

end
fclose('all');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Determine floors sorrounding staircase

%Use first and last plane of the set of steps

%Fisrt plane-check if we have a tread or riser
if (planes2.p(1).eq(1)==0 && planes2.p(1).eq(2)==0) %a tread
    lowZ=planes2.p(1).z(1);
end

if (planes2.p(1).eq(1)~=0 && planes2.p(1).eq(2)~=0) %a riser
    lowZ=min(planes2.p(1).z);
end

%Last plane-check if we have a tread or riser
if (planes2.p(planes2.tot).eq(1)==0 && planes2.p(planes2.tot).eq(2)==0) %a tread
    highZ=planes2.p(planes2.tot).z(1);
end

if (planes2.p(planes2.tot).eq(1)~=0 && planes2.p(planes2.tot).eq(2)~=0) %a riser
    highZ=max(planes2.p(planes2.tot).z);
end

%Loop over all ceiling/floors to find those close to the staircase (usually
%two)
difL=zeros(max(CF),1) + 10000000;
difH=zeros(max(CF),1) + 10000000;
for p=1:1:size(CF,1)
    cplane=CF(p);

    Zvalue=planes.p(cplane).z(1);
    difL(cplane)=abs(Zvalue-lowZ);
    difH(cplane)=abs(Zvalue-highZ);
end

%Select the two min values of difL and difH
[minL,IdxL]=sort(difL); %Sort diferences

[minH,IdxH]=sort(difH); %Sort diferences

%If the direrence between min two values is larger than threshold, pick
%the minimum value
dif2minsL=abs(minL(1)-minL(2));

if(dif2minsL>=abs(minL(1)))
    floorToUse=IdxL(1);
else %otherwise, compare distance between centroids of whole staircase and centroid of the two planes with similar min values
    plane1Centroid=getCentroid(planes.p(IdxL(1)).x, planes.p(IdxL(1)).y, planes.p(IdxL(1)).z);
    plane2Centroid=getCentroid(planes.p(IdxL(2)).x, planes.p(IdxL(2)).y, planes.p(IdxL(2)).z);

    allCentroids.x=[];
    allCentroids.y=[];
    allCentroids.z=[];
    for c=1:1:planes2.tot
        allCentroids.x=[allCentroids.x; planes2.p(c).centroid(1)];
        allCentroids.y=[allCentroids.y; planes2.p(c).centroid(2)];
        allCentroids.z=[allCentroids.z; planes2.p(c).centroid(3)];
    end

    theCentroid=getCentroid(allCentroids.x', allCentroids.y', allCentroids.z');
    p1=[theCentroid(1) theCentroid(2) theCentroid(3)];
    p2=[plane1Centroid(1) plane1Centroid(2) plane1Centroid(3)];
    p3=[plane2Centroid(1) plane2Centroid(2) plane2Centroid(3)];

    dis2plane1 = getDistance(p1,p2);
    dis2plane2 = getDistance(p1,p3);



    if (min(dis2plane1)<min(dis2plane2))
        floorToUse=IdxL(1);
    else
        floorToUse=IdxL(2);
    end

    %!!!!!!!!!!!!!DEBUG
    %floorToUse=1;
    %!!!!!!!!!!!!!!
    floorToUse;
    
end

%If the diference between min two values is larger than threshold, pick
%the minimum value
dif2minsH=abs(minH(1)-minH(2));

if(dif2minsH>=abs(minH(1)))
    ceilingToUse=IdxH(1);
else %otherwise, Compare distance between centroids of whole staircase and centroid of the two planes with similar min values
    plane1Centroid=getCentroid(planes.p(IdxH(1)).x, planes.p(IdxH(1)).y, planes.p(IdxH(1)).z);
    plane2Centroid=getCentroid(planes.p(IdxH(2)).x, planes.p(IdxH(2)).y, planes.p(IdxH(2)).z);


    allCentroids.x=[];
    allCentroids.y=[];
    allCentroids.z=[];
    for c=1:1:planes2.tot
        allCentroids.x=[allCentroids.x; planes2.p(c).centroid(1)];
        allCentroids.y=[allCentroids.y; planes2.p(c).centroid(2)];
        allCentroids.z=[allCentroids.z; planes2.p(c).centroid(3)];
    end

    theCentroid=getCentroid(allCentroids.x', allCentroids.y', allCentroids.z');
    p1=[theCentroid(1) theCentroid(2) theCentroid(3)];
    p2=[plane1Centroid(1) plane1Centroid(2) plane1Centroid(3)];
    p3=[plane2Centroid(1) plane2Centroid(2) plane2Centroid(3)];


    dis2plane1 = getDistance(p1,p2);
    dis2plane2 = getDistance(p1,p3);

    if (min(dis2plane1)<min(dis2plane2))
        ceilingToUse=IdxH(1);
    else
        ceilingToUse=IdxH(2);
    end


    
    ceilingToUse;

end

    %!!!!!!!!!!!!!DEBUG
    %ceilingToUse=2;
    %!!!!!!!!!!!!!!

%Correct the extension of steps and the total no. of steps

%Remove any extra step planes
toRemove=[ ];
for c=1:1:planes2.tot
    if (min(planes2.p(c).z) < planes.p(floorToUse).z(1) || max(planes2.p(c).z) > planes.p(ceilingToUse).z(1) )
        toRemove=[toRemove, c];
    end
end

planes2.p(toRemove)=[];
planes2.tot=size(planes2.p,2);

%Remove first and last planes if either is a tread (treads overlap with
%floor/ceiling)
toRemove=[ ];
%Fisrt plane-check if we have a tread or riser
if (planes2.p(1).eq(1)==0 && planes2.p(1).eq(2)==0) %a tread
    toRemove=[toRemove, 1];
end

%Last plane-check if we have a tread or riser
if (planes2.p(planes2.tot).eq(1)==0 && planes2.p(planes2.tot).eq(2)==0) %a tread
    toRemove=[toRemove, planes2.tot];
end

planes2.p(toRemove)=[];
planes2.tot=size(planes2.p,2);


%Determine the step height
stepHeight=abs(min(planes2.p(1).z)-max(planes2.p(1).z));


%Translate all planes of staircase in Z direction so last plane touches
%ceilingToUse (if distance to ceiling is less than half the step height)
tranZ=planes.p(ceilingToUse).z(1)-max(planes2.p(planes2.tot).z);

if (abs(tranZ)<(stepHeight/2))
    translation=true;
    for c=1:1:planes2.tot
        planes2.p(c).z= planes2.p(c).z+tranZ;
        planes2.p(c).centroid=[ ]; %centroid has changed
    end
else%if distance to floor more than half the step height, add steps

    translation=false;

    %Calculate the no. of full steps that can be added
    toAdd=ceil(abs(tranZ)/stepHeight); %use transZ as it is the distance to ceilingToUse

    %Get intital del. points
    idxMax=find(planes2.p(planes2.tot).z==max(planes2.p(planes2.tot).z));%last plane in the structure at this point is a rise
    prevXs=planes2.p(planes2.tot).x(idxMax);
    prevYs=planes2.p(planes2.tot).y(idxMax);
    prevZ=max(planes2.p(planes2.tot).z);

    %Get orientation of steps
    %second last plane in the structure at this point is a tread
    deltaX=planes2.p(planes2.tot-1).x(1)-planes2.p(planes2.tot-1).x(4);
    deltaY=planes2.p(planes2.tot-1).y(1)-planes2.p(planes2.tot-1).y(4);


    %Loop over and add steps (toAdd)
    tread=true; %start with a tread
    for c=planes2.tot+1:1:planes2.tot+(toAdd*2) %end with a rise
        if (tread)
            %eq. of the plane
            planes2.p(c).eq=[0 0 1 prevZ]';

            %delimiting points
            planes2.p(c).npoints=4;
            planes2.p(c).x=[prevXs(1)  prevXs(2) prevXs(2)-deltaX prevXs(1)-deltaX];
            planes2.p(c).y=[prevYs(1)  prevYs(2) prevYs(2)-deltaY prevYs(1)-deltaY];
            planes2.p(c).z=[prevZ prevZ prevZ prevZ];
            prevXs=[planes2.p(c).x(3)  planes2.p(c).x(4)];
            prevYs=[planes2.p(c).y(3)  planes2.p(c).y(4)];

            tread=false;

            continue;
        end

        if (~tread)

            %delimiting points
            planes2.p(c).npoints=4;
            planes2.p(c).x=[prevXs(1)  prevXs(2) prevXs(2) prevXs(1)];
            planes2.p(c).y=[prevYs(1)  prevYs(2) prevYs(2) prevYs(1)];
            planes2.p(c).z=[prevZ prevZ prevZ+stepHeight prevZ+stepHeight];

            %eq. of the plane
            A=[planes2.p(c).x(1) planes2.p(c).y(1) planes2.p(c).z(1)];
            B=[planes2.p(c).x(2) planes2.p(c).y(2) planes2.p(c).z(2)];
            C=[planes2.p(c).x(3) planes2.p(c).y(3) planes2.p(c).z(3)];
            equation = planeEquation(A,B,C);
            planes2.p(c).eq=[equation(1)  equation(2) equation(3) equation(4)]';

            tread=true;
            prevZ=max(planes2.p(c).z);
            continue;
        end

    end

    %Update tot. no. of planes
    planes2.tot=size(planes2.p,2);

    %Get distance bewteen last planes and ceilingToUse
    tranZ=planes.p(ceilingToUse).z(1)-max(planes2.p(planes2.tot).z);

    %Shift planes in Z direction (by tranZ)
    translation=true;
    for c=1:1:planes2.tot
        planes2.p(c).z= planes2.p(c).z+tranZ;
        planes2.p(c).centroid=[ ]; %centroid has changed
    end

end

%Check distance to floor after translating
if (translation)

    difFloor=planes.p(floorToUse).z(1)-min(planes2.p(1).z);

    if(abs(difFloor)<(stepHeight*.15)) %if the difference is less than 15% of the height of the step, correct steps height with out adding any more steps
        noRisers=ceil(planes2.tot/2); %no. of risers in the set of planes (first plane and last are always risers at this point)
        inc=abs(difFloor)/noRisers;

        idx=find(planes2.p(planes2.tot).z==min(planes2.p(planes2.tot).z));
        planes2.p(planes2.tot).z(idx)= planes2.p(planes2.tot).z(idx)-inc; %first plane is always a riser

        prevZ=min(planes2.p(planes2.tot).z);

        acc=1;
        %Loop over rest of planes
        for c=planes2.tot-1:-1:1 %start with the next plane closest to ceilingToUse

            if (planes2.p(c).eq(1)==0 && planes2.p(c).eq(1)==0) %a tread
                planes2.p(c).z(1:4)= prevZ;
            end

            if (planes2.p(c).eq(1)~=0 && planes2.p(c).eq(1)~=0) %a riser
                planes2.p(c).z=planes2.p(c).z-(inc*acc);
                idx=find(planes2.p(c).z==min(planes2.p(c).z));
                planes2.p(c).z(idx)= planes2.p(c).z(idx)-inc;
                acc=acc+1;
                prevZ= planes2.p(c).z(idx(1));
            end

        end

    end

    if(abs(difFloor)>=(stepHeight*.15)) %if the difference is greater than 15% of the height of the step, correct by adding addtional steps (at least one more step to be added)

        stairCaseHeight = abs(planes.p(floorToUse).z(1) - planes.p(ceilingToUse).z(1)); %height of staircase

        newSteps = ceil(stairCaseHeight/stepHeight); %at least one more step to be added

        newStepHeight=stairCaseHeight/newSteps; %new height of steps

        if (abs(newStepHeight-stepHeight)<=.10*stepHeight) %if difference between new height and previous height is less than 10% of previous height, adjust step height only

            maxZ=max(planes2.p(planes2.tot).z);
            idxMin=find(planes2.p(planes2.tot).z==min(planes2.p(planes2.tot).z));
            planes2.p(planes2.tot).z(idxMin)= maxZ - newStepHeight; %last plane is always a riser

            prevZ=min(planes2.p(planes2.tot).z);

            %Loop over rest of planes
            for c=planes2.tot-1:-1:1 %start with the next plane closest to ceilingToUse

                if (planes2.p(c).eq(1)==0 && planes2.p(c).eq(2)==0) %a tread
                    planes2.p(c).z(1:4)= prevZ;
                end

                if (planes2.p(c).eq(1)~=0 && planes2.p(c).eq(2)~=0) %a riser
                    idxMax=find(planes2.p(c).z==max(planes2.p(c).z));
                    idxMin=find(planes2.p(c).z==min(planes2.p(c).z));
                    planes2.p(c).z(idxMax)= prevZ;
                    planes2.p(c).z(idxMin)= prevZ - newStepHeight;
                    prevZ=min(planes2.p(c).z);
                end

            end


            %Get the intial delimiting points for first plane (a tread) of
            %additional steps
            idxMin=find(planes2.p(1).z==min(planes2.p(1).z));%first plane in the structure at this point is a rise
            prevXs=planes2.p(1).x(idxMin);
            prevYs=planes2.p(1).y(idxMin);
            prevZ=min(planes2.p(1).z);

            %Get orientation of steps
            %second plane in the structure at this point is a tread
            deltaX=planes2.p(2).x(1)-planes2.p(2).x(4);
            deltaY=planes2.p(2).y(1)-planes2.p(2).y(4);

            %Add aditional planes
            prevSteps = ceil(planes2.tot/2); %tot no. of current planes correspond to these many steps taking into account ceilingToUse

            toAdd=newSteps-prevSteps; %These many steps have to be added (two planes per step-a tread follow by a riser (direction downstairs)). These are added
            %at the beginning of structure planes2

            %Redorder existing planes in planes2
            for c=planes2.tot:-1:1
                planes2.p(c+(toAdd*2))=planes2.p(c);
            end


            tread=true; %start with a tread
            %for c=planes2.tot+1:1:planes2.tot+(toAdd*2)
            for c=toAdd*2:-1:1
                if (tread)
                    %eq. of the plane
                    planes2.p(c).eq=[0 0 1 prevZ]';

                    %delimiting points
                    planes2.p(c).npoints=4;
                    planes2.p(c).x=[prevXs(1)  prevXs(2) prevXs(2)+deltaX prevXs(1)+deltaX];
                    planes2.p(c).y=[prevYs(1)  prevYs(2) prevYs(2)+deltaY prevYs(1)+deltaY];
                    planes2.p(c).z=[prevZ prevZ prevZ prevZ];
                    prevXs=[planes2.p(c).x(3)  planes2.p(c).x(4)];
                    prevYs=[planes2.p(c).y(3)  planes2.p(c).y(4)];

                    tread=false;

                    continue;
                end

                if (~tread)


                    %delimiting points
                    planes2.p(c).npoints=4;
                    planes2.p(c).x=[prevXs(1)  prevXs(2) prevXs(2) prevXs(1)];
                    planes2.p(c).y=[prevYs(1)  prevYs(2) prevYs(2) prevYs(1)];
                    planes2.p(c).z=[prevZ prevZ prevZ-newStepHeight prevZ-newStepHeight];

                    %eq. of the plane
                    A=[planes2.p(c).x(1) planes2.p(c).y(1) planes2.p(c).z(1)];
                    B=[planes2.p(c).x(2) planes2.p(c).y(2) planes2.p(c).z(2)];
                    C=[planes2.p(c).x(3) planes2.p(c).y(3) planes2.p(c).z(3)];
                    equation = planeEquation(A,B,C);
                    planes2.p(c).eq=[equation(1)  equation(2) equation(3) equation(4)]';

                    tread=true;
                    prevZ=min(planes2.p(c).z);
                    continue;
                end

            end

            planes2.tot=size(planes2.p,2);



        else %adjust step height and size of threads -->to be implemented
            disp('WARNING: missing steps (floor)');
        end
    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Determine walls sorrounding staircase
wallsToUse=[ ];

%Use first  step to determine direction of staircase
if (planes2.p(1).eq(1)==0 && planes2.p(1).eq(2)==0)    %first plane is a thread, use second plane whic is a rise rise
    if (abs(planes2.p(2).eq(1)) > abs(planes2.p(2).eq(2)))
        %staircase along X-direction
        wallsToUse=wallsY;
    end
    if (abs(planes2.p(2).eq(1)) < abs(planes2.p(2).eq(2)))
        %staircase along Y-direction
        wallsToUse=wallsX;
    end
else
    if (abs(planes2.p(1).eq(1)) > abs(planes2.p(1).eq(2)))
        %staircase along X-direction
        wallsToUse=wallsY;
    end
    if (abs(planes2.p(1).eq(1)) < abs(planes2.p(1).eq(2)))
        %staircase along Y-direction
        wallsToUse=wallsX;
    end
end

%Find wall sorrounding steps within wallsToUse(usually two walls per set of steps, one of which is usually the handrail)

%Calcualte centroid of the set of steps
allCentroids.x=[];
allCentroids.y=[];
allCentroids.z=[];
for c=1:1:planes2.tot
    planes2.p(c).centroid = getCentroid(planes2.p(c).x, planes2.p(c).y, planes2.p(c).z);
    allCentroids.x=[allCentroids.x; planes2.p(c).centroid(1)];
    allCentroids.y=[allCentroids.y; planes2.p(c).centroid(2)];
    allCentroids.z=[allCentroids.z; planes2.p(c).centroid(3)];
end

theCentroid=getCentroid(allCentroids.x', allCentroids.y', allCentroids.z');

%Calculate distance from each wall's centroid in wallsToUse to theCentroid
%Loop over walls in wallsToUse
distances=zeros(max(wallsToUse),1) + 10000000;

p1=[theCentroid(1) theCentroid(2) theCentroid(3)];
for p=1:1:size(wallsToUse,1)
    cplane=wallsToUse(p);

    wallCentroid=getCentroid(planes.p(cplane).x, planes.p(cplane).y, planes.p(cplane).z);
    p2=[wallCentroid(1) wallCentroid(2) wallCentroid(3)];
    newDistance = getDistance(p1,p2);
    distances(cplane) = newDistance;

end

[D,I]=sort(distances); %Sort distances1 and pick the two smallest

%!!!!!!!!!!!!!DEBUG
 %I(2)=7;
 %I(3)=5;
%  I(1)=6;
%  I(2)=8;
%  I(3)=7;
%!!!!!!!!!!!!!

wallsFound=[I(1) I(2) I(3)]; %Usually I(1) and I(3) are the walls and I(2) is the handrail

%double check walls in wallsFound by using a single plane in planes2 and
%its distance to walls in wallsFound
cplane=floor(size(planes2.p,2)/2);

for cwall=1:1:size(wallsFound,2)
    distances=[];
    eq=planes.p(wallsFound(cwall)).eq';
    
    for cpoint=1:1:planes2.p(cplane).npoints
        p=[planes2.p(cplane).x(cpoint) planes2.p(cplane).y(cpoint) planes2.p(cplane).z(cpoint)];
        distances=[distances, abs(point2planeDistance(p,eq))];
    end
    minDistToWallsFound(cwall)=min(distances);
end

[D,Y]=sort(minDistToWallsFound, 'ascend');

wallsFound(1)=I(Y(1));
wallsFound(2)=I(Y(2));
wallsFound(3)=I(Y(3));
I(1)=wallsFound(1);
I(2)=wallsFound(2);
I(3)=wallsFound(3);

%Use walls found to align handrail, rotate steps and adjust width of steps

%Find those delimiting points (of walls in wallFound) that describe a line on the
%Z-plane

%Line 1--> p1,p2
[value,index]=min(planes.p(I(1)).z); %min value of Z
a=find(planes.p(I(1)).z==planes.p(I(1)).z(index)); %all points with equal value as min value of Z
if (size(a,2)<2)
    disp('Warning! Only one delimint point found with minimum Z');
end
t1=find(a==index);
t2=find(a~=index);

b=a(t2(1));
a=a(t1(1));

p1=[planes.p(I(1)).x(a) planes.p(I(1)).y(a) planes.p(I(1)).z(a)];
p2=[planes.p(I(1)).x(b) planes.p(I(1)).y(b) planes.p(I(1)).z(b)];

%Line 2--> p3,p4
[value,index]=min(planes.p(I(2)).z); %min value of Z
a=find(planes.p(I(2)).z==planes.p(I(2)).z(index)); %all points with equal value as min value of Z
if (size(a,2)<2)
    disp('Warning! Only one delimint point found with minimum Z');
end
t1=find(a==index);
t2=find(a~=index);

b=a(t2(1));
a=a(t1(1));

p3=[planes.p(I(2)).x(a) planes.p(I(2)).y(a) planes.p(I(2)).z(a)];
p4=[planes.p(I(2)).x(b) planes.p(I(2)).y(b) planes.p(I(2)).z(b)];

%Line 3--> p5,p6
[value,index]=min(planes.p(I(3)).z); %min value of Z
a=find(planes.p(I(3)).z==planes.p(I(3)).z(index)); %all points with equal value as min value of Z
if (size(a,2)<2)
    disp('Warning! Only one delimint point found with minimum Z');
end
t1=find(a==index);
t2=find(a~=index);

b=a(t2(1));
a=a(t1(1));

p5=[planes.p(I(3)).x(a) planes.p(I(3)).y(a) planes.p(I(3)).z(a)];
p6=[planes.p(I(3)).x(b) planes.p(I(3)).y(b) planes.p(I(3)).z(b)];



%Use walls found to align handrail
%%%%%%%%%%%%%%%%%%%%%%%
if align==1
    %We use the wall closest to the steps (I(1) or I(2))
    %Determine which one is a wall by comparing heights.
    height1=max(planes.p(I(1)).z) - min(planes.p(I(1)).z); %max value of z - min value of Z
    height2=max(planes.p(I(2)).z) - min(planes.p(I(2)).z); %max value of z - min value of Z

    if height1>height2
        %Wall is I(1)
        handRail=I(2);
        WallAp1=[p1(1) p1(2)  0];
        WallAp2=[p2(1) p2(2) 0];
        WallBp1=[p5(1) p5(2)  0];%I(3) is the other wall
        WallBp2=[p6(1) p6(2) 0];
    else
        %Wall is I(2) 
        handRail=I(1);
        WallAp1=[p3(1) p3(2)  0];
        WallAp2=[p4(1) p4(2) 0];
        WallBp1=[p5(1) p5(2)  0]; %I(3) is the other wall
        WallBp2=[p6(1) p6(2) 0];
    end
    
    %Calculate distance between walls using WallAp1,p2 and WallBp1,p2
    
    %project WallBp1 onto line described by WallAp1-WallAp2
    projWallBp1 = point2Line3D(WallBp1, WallAp1, WallAp2);
    %project WallBp2 onto line described by WallAp1-WallAp2
    projWallBp2 = point2Line3D(WallBp2, WallAp1, WallAp2);
    
    %Calculate distance between WallBp1,p2 and projWallBp1,p3
     distWallBp1x = WallBp1(1)-projWallBp1(1);
     distWallBp1y = WallBp1(2)-projWallBp1(2);
     
     distWallBp2x = WallBp2(1)-projWallBp2(1);
     distWallBp2y = WallBp2(2)-projWallBp2(2);
     
    
    avgDistX=(distWallBp1x+distWallBp2x)/2;
    avgDistY=(distWallBp1y+distWallBp2y)/2;
    
    
    
    %Generate new wall I(3) using avgDist
    %get equation of new plane
    A=[WallAp1(1)+avgDistX WallAp1(2)+avgDistY 0];
    B=[WallAp1(1)+avgDistX WallAp1(2)+avgDistY 10];
    C=[WallAp2(1)+avgDistX WallAp2(2)+avgDistY 0];
    newPlaneEq = planeEquation(A,B,C);
    
    %Project del. point of I(3) onto newPlane   
    for pt=1:1:planes.p(I(3)).npoints
        delPt=[planes.p(I(3)).x(pt) planes.p(I(3)).y(pt) planes.p(I(3)).z(pt)];
        projPt = point2Plane(delPt,newPlaneEq);
        planes.p(I(3)).x(pt) = projPt(1);
        planes.p(I(3)).y(pt) = projPt(2);
        planes.p(I(3)).z(pt) = projPt(3);
    end
    planes.p(I(3)).eq(1)=newPlaneEq(1);
    planes.p(I(3)).eq(2)=newPlaneEq(2);
    planes.p(I(3)).eq(3)=newPlaneEq(3);
    planes.p(I(3)).eq(4)=newPlaneEq(4);
   
    
    %Align handrail using I(3) and wall
    %Generate new handrail using avgDist/2
    %get equation of new plane
    A=[WallAp1(1)+(avgDistX/2) WallAp1(2)+(avgDistY/2) 0];
    B=[WallAp1(1)+(avgDistX/2) WallAp1(2)+(avgDistY/2) 10];
    C=[WallAp2(1)+(avgDistX/2) WallAp2(2)+(avgDistY/2) 0];
    newPlaneEq = planeEquation(A,B,C);
 
     %Project del. point of handRail onto newPlane   
    for pt=1:1:planes.p(handRail).npoints
        delPt=[planes.p(handRail).x(pt) planes.p(handRail).y(pt) planes.p(handRail).z(pt)];
        projPt = point2Plane(delPt,newPlaneEq);
        planes.p(handRail).x(pt) = projPt(1);
        planes.p(handRail).y(pt) = projPt(2);
        planes.p(handRail).z(pt) = projPt(3);
    end
    planes.p(handRail).eq(1)=newPlaneEq(1);
    planes.p(handRail).eq(2)=newPlaneEq(2);
    planes.p(handRail).eq(3)=newPlaneEq(3);
    planes.p(handRail).eq(4)=newPlaneEq(4);
    
end

%Update values for new wall and handrail
%Line 1--> p1,p2
[value,index]=min(planes.p(I(1)).z); %min value of Z
a=find(planes.p(I(1)).z==planes.p(I(1)).z(index)); %all points with equal value as min value of Z
if (size(a,2)<2)
    disp('Warning! Only one delimint point found with minimum Z');
end
t1=find(a==index);
t2=find(a~=index);

b=a(t2(1));
a=a(t1(1));

p1=[planes.p(I(1)).x(a) planes.p(I(1)).y(a) planes.p(I(1)).z(a)];
p2=[planes.p(I(1)).x(b) planes.p(I(1)).y(b) planes.p(I(1)).z(b)];

%Line 2--> p3,p4
[value,index]=min(planes.p(I(2)).z); %min value of Z
a=find(planes.p(I(2)).z==planes.p(I(2)).z(index)); %all points with equal value as min value of Z
if (size(a,2)<2)
    disp('Warning! Only one delimint point found with minimum Z');
end
t1=find(a==index);
t2=find(a~=index);

b=a(t2(1));
a=a(t1(1));

p3=[planes.p(I(2)).x(a) planes.p(I(2)).y(a) planes.p(I(2)).z(a)];
p4=[planes.p(I(2)).x(b) planes.p(I(2)).y(b) planes.p(I(2)).z(b)];

%Line 3--> p5,p6
[value,index]=min(planes.p(I(3)).z); %min value of Z
a=find(planes.p(I(3)).z==planes.p(I(3)).z(index)); %all points with equal value as min value of Z
if (size(a,2)<2)
    disp('Warning! Only one delimint point found with minimum Z');
end
t1=find(a==index);
t2=find(a~=index);

b=a(t2(1));
a=a(t1(1));

p5=[planes.p(I(3)).x(a) planes.p(I(3)).y(a) planes.p(I(3)).z(a)];
p6=[planes.p(I(3)).x(b) planes.p(I(3)).y(b) planes.p(I(3)).z(b)];

%%%%%%%%%%%%%%%%%%%%%


%Rotate set of steps so they are aligend to wall (not handrail), if rot=1
%%%%%%%%%%%%%%%

if rot==1
    %Determine the height of walls in wallFound
    %The one with the largest height is the wall, the other is the handrail

    height1=max(planes.p(I(1)).z) - min(planes.p(I(1)).z); %max value of z - min value of Z
    height2=max(planes.p(I(2)).z) - min(planes.p(I(2)).z); %max value of z - min value of Z

    if height1>height2
        %Use I(1)
        Wallp1=[p1(1) p1(2)  0];
        Wallp2=[p2(1) p2(2) 0];
    else
        %Use I(2) 
        Wallp1=[p3(1) p3(2)  0];
        Wallp2=[p4(1) p4(2) 0];
    end


     Vwall=Wallp1-Wallp2;
    magVwall=sqrt(sum(Vwall.^2));
    Vwall=Vwall/magVwall;
     
    % Vwall should point toward the main postive direction
    if (abs(Vwall(2))>abs(Vwall(1))) %pointing towards Y
        if (Vwall(2)<0)
            Vwall=Vwall*-1;
        end 
    else %pointing towards X
        if (Vwall(1)<0)
            Vwall=Vwall*-1;
        end
    end

    %vector  of a step as projected on x-y plane
    %Use the first  thred
    if (planes2.p(1).eq(1)==0 && planes2.p(1).eq(2)==0)    %first plane is a thread, use second plane which is a rise
        Vstair=[planes2.p(2).eq(1) planes2.p(2).eq(2) 0];
        magVstair=sqrt(sum(Vstair.^2));
        Vstair=Vstair/magVstair;
    else %use first plane which is a rise
        Vstair=[planes2.p(1).eq(1) planes2.p(1).eq(2) 0];
        magVstair=sqrt(sum(Vstair.^2));
        Vstair=Vstair/magVstair;
    end

   % Vstair should point toward the main postive direction
    if (abs(Vstair(2))>abs(Vstair(1))) %pointing towards Y
        if (Vstair(2)<0)
            Vstair=Vstair*-1;
        end 
    else %pointing towards X
        if (Vstair(1)<0)
            Vstair=Vstair*-1;
        end
    end
    
    
    %Calculate angle of Vstair vector with Vwall
    angleSW=acos(dot(Vstair,Vwall));
    angleSW=min([angleSW (pi-angleSW)]);
    
    %Determine if we need to rotate counter(-) or clockwise (+)
    if abs(Vstair(2))>abs(Vstair(1)) %if true, vector with main direction along y-asis
        if  abs(Vstair(1)) > abs(Vwall(1))
            angleSW=-1*angleSW;
        end
    else %if true, vector with main direction along x-asis
        if  abs(Vstair(2)) < abs(Vwall(2))
            angleSW=-1*angleSW;
        end
    end
    
    %angleSW*90/pi/2

    %iterate ove all planes in steps and rotate by angle angleSW
    for cplane=1:1:planes2.tot

        for cpoint=1:1:planes2.p(cplane).npoints
            newX =  (planes2.p(cplane).x(cpoint)*cos(angleSW)) + (planes2.p(cplane).y(cpoint)*(-1*sin(angleSW))); %rotate the point according to angleSW, and update value in structure
            newY =  (planes2.p(cplane).x(cpoint)*sin(angleSW)) + (planes2.p(cplane).y(cpoint)*(cos(angleSW)));
            planes2.p(cplane).x(cpoint) = newX;
            planes2.p(cplane).y(cpoint) = newY;
        end

    end
    
    %Calcualte NEW centroid of the set of steps
    allCentroids.x=[];
    allCentroids.y=[];
    allCentroids.z=[];
    for c=1:1:planes2.tot
        planes2.p(c).centroid = getCentroid(planes2.p(c).x, planes2.p(c).y, planes2.p(c).z);
        allCentroids.x=[allCentroids.x; planes2.p(c).centroid(1)];
        allCentroids.y=[allCentroids.y; planes2.p(c).centroid(2)];
        allCentroids.z=[allCentroids.z; planes2.p(c).centroid(3)];
    end

    %Compensate for changes in the centroid
    theNewCentroid=getCentroid(allCentroids.x', allCentroids.y', allCentroids.z');
    difCentroid=theNewCentroid-theCentroid;
    
    for cplane=1:1:planes2.tot

        for cpoint=1:1:planes2.p(cplane).npoints
            planes2.p(cplane).x(cpoint) = planes2.p(cplane).x(cpoint)-difCentroid(1);
            planes2.p(cplane).y(cpoint) = planes2.p(cplane).y(cpoint)-difCentroid(2);
            planes2.p(cplane).z(cpoint) = planes2.p(cplane).z(cpoint)-difCentroid(3);
        end

    end
    
    
end

%%%%%%%%%%%%%%%




%Increase length of lines
%Line1
[m1,b1]=line_param(p1(1),p2(1),p1(2),p2(2));

if p1(1)>=p2(1)
    p1(1)=100000;
    p1(2)=(m1*p1(1))+b1;

    p2(1)=-100000;
    p2(2)=(m1*p2(1))+b1;

end

if p1(1)<p2(1)
    p1(1)=-100000;
    p1(2)=(m1*p1(1))+b1;

    p2(1)=100000;
    p2(2)=(m1*p2(1))+b1;

end

%line2
[m2,b2]=line_param(p3(1),p4(1),p3(2),p4(2));

if p3(1)>=p4(1)
    p3(1)=100000;
    p3(2)=(m2*p3(1))+b2;

    p4(1)=-100000;
    p4(2)=(m2*p4(1))+b2;

end

if p3(1)<p4(1)
    p3(1)=-100000;
    p3(2)=(m2*p3(1))+b2;

    p4(1)=100000;
    p4(2)=(m2*p4(1))+b2;

end

%make Z component 0, i.e., projected point to Z-plane
p1(3)=0;
p2(3)=0;
p3(3)=0;
p4(3)=0;

%Loop over steps and adjust each step using the lines defined by p1-p2
%and p3-4
for cplane=1:1:planes2.tot

    for cpoint=1:1:planes2.p(cplane).npoints %Get the points delimiting plane

        %Compute distances of delimintg points of each step to line defined by
        %p1,p2
        p=[planes2.p(cplane).x(cpoint)  planes2.p(cplane).y(cpoint) 0];%make Z component 0, i.e., porjected point to Z-plane
        distance= point2LineDistance(p,p1,p2);
        planes2.p(cplane).distance1(cpoint)=distance; %store distance

        %Compute distances of delimintg points of each step to line defined by
        %p3,p4
        p=[planes2.p(cplane).x(cpoint)  planes2.p(cplane).y(cpoint) 0];%make Z component 0, i.e., porjected point to Z-plane
        distance= point2LineDistance(p,p3,p4);
        planes2.p(cplane).distance2(cpoint)=distance; %store distance

    end

    %Adust using line defined by p1,p2
    [D,I]=sort(planes2.p(cplane).distance1); %Sort distances and pick the two smallest
    
    %!!!!!!!!!!!DEBUG
    %[D,I]=sort(planes2.p(cplane).distance1,'descend');
    %!!!!!!!!!!!


    pA=[planes2.p(cplane).x(I(1))  planes2.p(cplane).y(I(1)) 0];%make Z component 0, i.e., projected point to Z-plane
    pB=[planes2.p(cplane).x(I(2))  planes2.p(cplane).y(I(2)) 0];%make Z component 0, i.e., projected point to Z-plane

    projPtA = point2Line3D(pA,p1,p2);%Project points to line
    projPtB = point2Line3D(pB,p1,p2);

    planes2.p(cplane).x(I(1)) =  projPtA(1); %store projected point in structure
    planes2.p(cplane).y(I(1)) = projPtA(2);

    planes2.p(cplane).x(I(2)) =  projPtB(1); %store projected point in structure
    planes2.p(cplane).y(I(2)) = projPtB(2);

    %Adust using line defined by p3,p4
    [D,I]=sort(planes2.p(cplane).distance2);%Sort distances and pick the two smallest

    
    pA=[planes2.p(cplane).x(I(1))  planes2.p(cplane).y(I(1)) 0];%make Z component 0, i.e., projected point to Z-plane
    pB=[planes2.p(cplane).x(I(2))  planes2.p(cplane).y(I(2)) 0];%make Z component 0, i.e., projected point to Z-plane

    projPtA = point2Line3D(pA,p3,p4);%Project points to line
    projPtB = point2Line3D(pB,p3,p4);

    planes2.p(cplane).x(I(1)) =  projPtA(1); %store projected point in structure
    planes2.p(cplane).y(I(1)) = projPtA(2);

    planes2.p(cplane).x(I(2)) =  projPtB(1); %store projected point in structure
    planes2.p(cplane).y(I(2)) = projPtB(2);


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Correct delimiting points of floorToUse and ceilingToUse

%%%%Correct ceilingToUse
idxMax=find(planes2.p(planes2.tot).z==max(planes2.p(planes2.tot).z)); %use last plane in structures planes2 (a riser). Get del. points with max Z value

pA=[planes2.p(planes2.tot).x(idxMax(1)) planes2.p(planes2.tot).y(idxMax(1)) planes2.p(planes2.tot).z(idxMax(1))]; %point A
pB=[planes2.p(planes2.tot).x(idxMax(2)) planes2.p(planes2.tot).y(idxMax(2)) planes2.p(planes2.tot).z(idxMax(2))];%point B

%Get distance from each del. point in celingToUse to pA and pB
%loop over del. points
for dp=1:1:planes.p(ceilingToUse).npoints
    p=[planes.p(ceilingToUse).x(dp) planes.p(ceilingToUse).y(dp) planes.p(ceilingToUse).z(dp)];

    distA(dp)=getDistance(pA,p);
    distB(dp)=getDistance(pB,p);

end

%Get min distance to pA and pB

idxMin_pA=find(distA==min(distA));
idxMin_pB=find(distB==min(distB));

idxs=[idxMin_pA idxMin_pB];
idxs=sort(idxs);
%Get no. of points between indices
noPointsAsc=idxs(2)-idxs(1);
noPointsDsc=(idxs(1)-1) + (planes.p(floorToUse).npoints-idxs(2));

noPoints=[noPointsAsc noPointsDsc];

%pick the path with the least amount of points
[p,pathIdx] = min(noPoints);
idxs;

if pathIdx==1 %ascending path

    %remove redundant del. points between idxs(1) and idxs(2)
    planes.p(ceilingToUse).x(idxs(1)+1:idxs(2)-1)= [ ];
    planes.p(ceilingToUse).y(idxs(1)+1:idxs(2)-1)= [ ];
    planes.p(ceilingToUse).z(idxs(1)+1:idxs(2)-1)= [ ];

    %shift del. points
    planes.p(ceilingToUse).x(idxs(1)+3:size(planes.p(ceilingToUse).x,2)+2)=planes.p(ceilingToUse).x(idxs(1)+1:size(planes.p(ceilingToUse).x,2));
    planes.p(ceilingToUse).y(idxs(1)+3:size(planes.p(ceilingToUse).y,2)+2)=planes.p(ceilingToUse).y(idxs(1)+1:size(planes.p(ceilingToUse).y,2));
    planes.p(ceilingToUse).z(idxs(1)+3:size(planes.p(ceilingToUse).z,2)+2)=planes.p(ceilingToUse).z(idxs(1)+1:size(planes.p(ceilingToUse).z,2));

%add the additional del. points
 if idxMin_pA<idxMin_pB
    planes.p(ceilingToUse).x(idxs(1)+1) = pA(1);
    planes.p(ceilingToUse).y(idxs(1)+1) = pA(2);
    planes.p(ceilingToUse).z(idxs(1)+1) = pA(3);
    planes.p(ceilingToUse).x(idxs(1)+2) = pB(1);
    planes.p(ceilingToUse).y(idxs(1)+2) = pB(2);
    planes.p(ceilingToUse).z(idxs(1)+2) = pB(3);
 end
 
  if idxMin_pA>idxMin_pB
     planes.p(ceilingToUse).x(idxs(1)+1) = pB(1);
    planes.p(ceilingToUse).y(idxs(1)+1) = pB(2);
    planes.p(ceilingToUse).z(idxs(1)+1) = pB(3);
    planes.p(ceilingToUse).x(idxs(1)+2) = pA(1);
    planes.p(ceilingToUse).y(idxs(1)+2) = pA(2);
    planes.p(ceilingToUse).z(idxs(1)+2) = pA(3);
 end
 
 if idxMin_pA==idxMin_pB
     p=[planes.p(ceilingToUse).x(idxs(1)+3) planes.p(ceilingToUse).y(idxs(1)+3) planes.p(ceilingToUse).z(idxs(1)+3)];
     dist2NextA=getDistance(pA,p);
     dist2NextB=getDistance(pB,p);
     %(min(distA)<=min(distB)) 
     if (dist2NextA>dist2NextB)
         planes.p(ceilingToUse).x(idxs(1)+1) = pA(1);
         planes.p(ceilingToUse).y(idxs(1)+1) = pA(2);
         planes.p(ceilingToUse).z(idxs(1)+1) = pA(3);
         planes.p(ceilingToUse).x(idxs(1)+2) = pB(1);
         planes.p(ceilingToUse).y(idxs(1)+2) = pB(2);
         planes.p(ceilingToUse).z(idxs(1)+2) = pB(3);
     else 
         planes.p(ceilingToUse).x(idxs(1)+1) = pB(1);
         planes.p(ceilingToUse).y(idxs(1)+1) = pB(2);
         planes.p(ceilingToUse).z(idxs(1)+1) = pB(3);
         planes.p(ceilingToUse).x(idxs(1)+2) = pA(1);
         planes.p(ceilingToUse).y(idxs(1)+2) = pA(2);
         planes.p(ceilingToUse).z(idxs(1)+2) = pA(3);
     end
 end
 

end

if pathIdx==2 %descending path

    %remove redundant del. points between idxs(1) and idxs(2)
    redundant1=[1:idxs(1)-1];
    redundant2=[idxs(2)+1:size(planes.p(ceilingToUse).x,2)];
     redundant=[redundant1, redundant2];
    planes.p(ceilingToUse).x(redundant)= [ ];
    planes.p(ceilingToUse).y(redundant)= [ ];
    planes.p(ceilingToUse).z(redundant)= [ ];

    %add the additional del. points
    planes.p(ceilingToUse).x(2:size(planes.p(ceilingToUse).x,2)+1) =  planes.p(ceilingToUse).x(1:size(planes.p(ceilingToUse).x,2));
    planes.p(ceilingToUse).y(2:size(planes.p(ceilingToUse).y,2)+1) =  planes.p(ceilingToUse).y(1:size(planes.p(ceilingToUse).y,2));
    planes.p(ceilingToUse).z(2:size(planes.p(ceilingToUse).z,2)+1) =  planes.p(ceilingToUse).z(1:size(planes.p(ceilingToUse).z,2));
    
    if idxMin_pA<idxMin_pB
        planes.p(ceilingToUse).x(1) = pA(1);
        planes.p(ceilingToUse).y(1) = pA(2);
        planes.p(ceilingToUse).z(1) = pA(3);
        planes.p(ceilingToUse).x(size(planes.p(ceilingToUse).x,2)+1) = pB(1);
        planes.p(ceilingToUse).y(size(planes.p(ceilingToUse).y,2)+1) = pB(2);
        planes.p(ceilingToUse).z(size(planes.p(ceilingToUse).z,2)+1) = pB(3);
    end

    if idxMin_pA>idxMin_pB
        planes.p(ceilingToUse).x(1) = pB(1);
        planes.p(ceilingToUse).y(1) = pB(2);
        planes.p(ceilingToUse).z(1) = pB(3);
        planes.p(ceilingToUse).x(size(planes.p(ceilingToUse).x,2)+1) = pA(1);
        planes.p(ceilingToUse).y(size(planes.p(ceilingToUse).y,2)+1) = pA(2);
        planes.p(ceilingToUse).z(size(planes.p(ceilingToUse).z,2)+1) = pA(3);
    end
    
    if idxMin_pA==idxMin_pB
        p=[planes.p(ceilingToUse).x(size(planes.p(ceilingToUse).x,2)) planes.p(ceilingToUse).y(size(planes.p(ceilingToUse).y,2)) planes.p(ceilingToUse).z(size(planes.p(ceilingToUse).z,2))];
        dist2NextA=getDistance(pA,p);
        dist2NextB=getDistance(pB,p);
        %(min(distA)<=min(distB))
        if  (dist2NextA>dist2NextB)
            planes.p(ceilingToUse).x(1) = pA(1);
            planes.p(ceilingToUse).y(1) = pA(2);
            planes.p(ceilingToUse).z(1) = pA(3);
            planes.p(ceilingToUse).x(size(planes.p(ceilingToUse).x,2)+1) = pB(1);
            planes.p(ceilingToUse).y(size(planes.p(ceilingToUse).y,2)+1) = pB(2);
            planes.p(ceilingToUse).z(size(planes.p(ceilingToUse).z,2)+1) = pB(3);
        else
            planes.p(ceilingToUse).x(1) = pB(1);
            planes.p(ceilingToUse).y(1) = pB(2);
            planes.p(ceilingToUse).z(1) = pB(3);
            planes.p(ceilingToUse).x(size(planes.p(ceilingToUse).x,2)+1) = pA(1);
            planes.p(ceilingToUse).y(size(planes.p(ceilingToUse).y,2)+1) = pA(2);
            planes.p(ceilingToUse).z(size(planes.p(ceilingToUse).z,2)+1) = pA(3);
        end
    end

    
end


planes.p(ceilingToUse).npoints=size(planes.p(ceilingToUse).x,2);

%%%%Correct floorToUse
clear distA;
clear distB;
clear idxs;
clear idxMin_pA;
clear idxMin_pB;
idxMin=find(planes2.p(1).z==min(planes2.p(1).z)); %use first plane in structures planes2 (a riser). Get del. points with min Z value

pA=[planes2.p(1).x(idxMin(1)) planes2.p(1).y(idxMin(1)) planes2.p(1).z(idxMin(1))]; %point A
pB=[planes2.p(1).x(idxMin(2)) planes2.p(1).y(idxMin(2)) planes2.p(1).z(idxMin(2))]; %point B

%Get distance from each del. point in floorToUse to pA and pB
%loop over del. points
for dp=1:1:planes.p(floorToUse).npoints
    p=[planes.p(floorToUse).x(dp) planes.p(floorToUse).y(dp) planes.p(floorToUse).z(dp)];

    distA(dp)=getDistance(pA,p);
    distB(dp)=getDistance(pB,p);

end

%Get min distance to pA and pB

idxMin_pA=find(distA==min(distA));
idxMin_pB=find(distB==min(distB));

idxs=[idxMin_pA idxMin_pB];

idxs=sort(idxs); %sort indices

%Get no. of points between indices
noPointsAsc=idxs(2)-idxs(1);
noPointsDsc=(idxs(1)-1) + (planes.p(floorToUse).npoints-idxs(2));

noPoints=[noPointsAsc noPointsDsc];

%pick the path with the least amount of points
[p,pathIdx] = min(noPoints);

if pathIdx==1 %ascending path

    %remove redundant del. points between idxs(1) and idxs(2)
    planes.p(floorToUse).x(idxs(1)+1:idxs(2)-1)= [ ];
    planes.p(floorToUse).y(idxs(1)+1:idxs(2)-1)= [ ];
    planes.p(floorToUse).z(idxs(1)+1:idxs(2)-1)= [ ];
    

    %add the additional del. points
    planes.p(floorToUse).x(idxs(1)+3:size(planes.p(floorToUse).x,2)+2)=planes.p(floorToUse).x(idxs(1)+1:size(planes.p(floorToUse).x,2));
    planes.p(floorToUse).y(idxs(1)+3:size(planes.p(floorToUse).y,2)+2)=planes.p(floorToUse).y(idxs(1)+1:size(planes.p(floorToUse).y,2));
    planes.p(floorToUse).z(idxs(1)+3:size(planes.p(floorToUse).z,2)+2)=planes.p(floorToUse).z(idxs(1)+1:size(planes.p(floorToUse).z,2));


 if idxMin_pA<idxMin_pB
    planes.p(floorToUse).x(idxs(1)+1) = pA(1);
    planes.p(floorToUse).y(idxs(1)+1) = pA(2);
    planes.p(floorToUse).z(idxs(1)+1) = pA(3);
    planes.p(floorToUse).x(idxs(1)+2) = pB(1);
    planes.p(floorToUse).y(idxs(1)+2) = pB(2);
    planes.p(floorToUse).z(idxs(1)+2) = pB(3);

 end
 if idxMin_pA>idxMin_pB
    planes.p(floorToUse).x(idxs(1)+1) = pB(1);
    planes.p(floorToUse).y(idxs(1)+1) = pB(2);
    planes.p(floorToUse).z(idxs(1)+1) = pB(3);
    planes.p(floorToUse).x(idxs(1)+2) = pA(1);
    planes.p(floorToUse).y(idxs(1)+2) = pA(2);
    planes.p(floorToUse).z(idxs(1)+2) = pA(3);
 end
 
 if idxMin_pA==idxMin_pB
     p=[planes.p(floorToUse).x(idxs(1)+3) planes.p(floorToUse).y(idxs(1)+3) planes.p(floorToUse).z(idxs(1)+3)];
     dist2NextA=getDistance(pA,p);
     dist2NextB=getDistance(pB,p);
     %(min(distA)<=min(distB))
     if  (dist2NextA>dist2NextB)
         planes.p(floorToUse).x(idxs(1)+1) = pA(1);
         planes.p(floorToUse).y(idxs(1)+1) = pA(2);
         planes.p(floorToUse).z(idxs(1)+1) = pA(3);
         planes.p(floorToUse).x(idxs(1)+2) = pB(1);
         planes.p(floorToUse).y(idxs(1)+2) = pB(2);
         planes.p(floorToUse).z(idxs(1)+2) = pB(3);
     else
         planes.p(floorToUse).x(idxs(1)+1) = pB(1);
         planes.p(floorToUse).y(idxs(1)+1) = pB(2);
         planes.p(floorToUse).z(idxs(1)+1) = pB(3);
         planes.p(floorToUse).x(idxs(1)+2) = pA(1);
         planes.p(floorToUse).y(idxs(1)+2) = pA(2);
         planes.p(floorToUse).z(idxs(1)+2) = pA(3);
     end
 end
 
 

end

if pathIdx==2 %descending path

    %remove redundant del. points between idxs(1) and idxs(2)
    redundant1=[1:idxs(1)-1];
    redundant2=[idxs(2)+1:size(planes.p(floorToUse).x,2)];
    redundant=[redundant1, redundant2];
    planes.p(floorToUse).x(redundant)= [ ];
    planes.p(floorToUse).y(redundant)= [ ];
    planes.p(floorToUse).z(redundant)= [ ];

    %add the additional del. points
    planes.p(floorToUse).x(2:size(planes.p(floorToUse).x,2)+1) =  planes.p(floorToUse).x(1:size(planes.p(floorToUse).x,2));
    planes.p(floorToUse).y(2:size(planes.p(floorToUse).y,2)+1) =  planes.p(floorToUse).y(1:size(planes.p(floorToUse).y,2));
    planes.p(floorToUse).z(2:size(planes.p(floorToUse).z,2)+1) =  planes.p(floorToUse).z(1:size(planes.p(floorToUse).z,2));
    
    if idxMin_pA<idxMin_pB
        planes.p(floorToUse).x(1) = pA(1);
        planes.p(floorToUse).y(1) = pA(2);
        planes.p(floorToUse).z(1) = pA(3);
        planes.p(floorToUse).x(size(planes.p(floorToUse).x,2)+1) = pB(1);
        planes.p(floorToUse).y(size(planes.p(floorToUse).y,2)+1) = pB(2);
        planes.p(floorToUse).z(size(planes.p(floorToUse).z,2)+1) = pB(3);
    end

    if idxMin_pA>idxMin_pB
        planes.p(floorToUse).x(1) = pB(1);
        planes.p(floorToUse).y(1) = pB(2);
        planes.p(floorToUse).z(1) = pB(3);
        planes.p(floorToUse).x(size(planes.p(floorToUse).x,2)+1) = pA(1);
        planes.p(floorToUse).y(size(planes.p(floorToUse).y,2)+1) = pA(2);
        planes.p(floorToUse).z(size(planes.p(floorToUse).z,2)+1) = pA(3);
    end

    if idxMin_pA==idxMin_pB
        p=[planes.p(floorToUse).x(size(planes.p(floorToUse).x,2)) planes.p(floorToUse).y(size(planes.p(floorToUse).y,2)) planes.p(floorToUse).z(size(planes.p(floorToUse).z,2))];
        dist2NextA=getDistance(pA,p);
        dist2NextB=getDistance(pB,p);
         %(min(distA)<=min(distB))
        if  (dist2NextA>dist2NextB)
            planes.p(floorToUse).x(1) = pA(1);
            planes.p(floorToUse).y(1) = pA(2);
            planes.p(floorToUse).z(1) = pA(3);
            planes.p(floorToUse).x(size(planes.p(floorToUse).x,2)+1) = pB(1);
            planes.p(floorToUse).y(size(planes.p(floorToUse).y,2)+1) = pB(2);
            planes.p(floorToUse).z(size(planes.p(floorToUse).z,2)+1) = pB(3);
        else
            planes.p(floorToUse).x(1) = pB(1);
            planes.p(floorToUse).y(1) = pB(2);
            planes.p(floorToUse).z(1) = pB(3);
            planes.p(floorToUse).x(size(planes.p(floorToUse).x,2)+1) = pA(1);
            planes.p(floorToUse).y(size(planes.p(floorToUse).y,2)+1) = pA(2);
            planes.p(floorToUse).z(size(planes.p(floorToUse).z,2)+1) = pA(3);
        end
    end


end


planes.p(floorToUse).npoints=size(planes.p(floorToUse).x,2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Save the adjusted steps 
fid = fopen([pathname  'ADJSTEPS_' filename ], 'wt');
fprintf(fid, '%i\n',planes2.tot); %Total number of planes in staircase
pointer=2;

%write adjusted steps
tot_planes=planes2.tot;
for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planes2.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes2.p(cplane).eq(1,1), planes2.p(cplane).eq(2,1),planes2.p(cplane).eq(3,1),planes2.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes2.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes2.p(cplane).x(cpoint), planes2.p(cplane).y(cpoint),planes2.p(cplane).z(cpoint));
    end

end
fclose('all');

%Save the adjusted walls and ceilings/floors
fid = fopen([pathname  'ADJWALLS_' filename ], 'wt');
fprintf(fid, '%i\n',planes.tot); %Total number of planes in staircase
pointer=2;

%write first walls and ceilings
%tot_planes=planes.tot;
tot_planes=planes.tot;
for cplane=1:1:tot_planes

    fprintf(fid, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint),planes.p(cplane).z(cpoint));
    end

end
fclose('all');


end

