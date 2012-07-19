function pvol =getOverlappingVol(planeE, planeR)

%determine bounding boxes

box1 = getBoundingBox(planeE);
box2 = getBoundingBox(planeR);

%Using box2 as reference get the overlapping section in Z
%box(5) min value of Z
%box(6) max value of Z

if box1(6)<=box2(5) ||  box1(5) >=box2(6) %if maxZ of plane E is less or equal than minZ of ref. plane, or if minZ of plane E is greater or equal than maxZ of ref. plane, make minZ and maxZ of overlapping volume =0

    overlapBox(5) = 0;
    overlapBox(6) = 0;

else

    if box1(5)<= box2(5) %if minZ of planeE is less or equal than minZ of the reference plane, make minZ of overlapping volume = minZ of ref. plane
        overlapBox(5)=box2(5);
    else %if minZ of planeE is greater than minZ of the reference plane, make minZ of overlapping volume = minZ of planeE
        overlapBox(5)=box1(5);
    end

    if box1(6)>= box2(6) %if maxZ of planeE is greater or equal than maxZ of the reference plane, make maxZ of overlapping volume = minZ of ref. plane
        overlapBox(6)=box2(6);
    else %if maxZ of planeE is less than maxZ of the reference plane, make maxZ of overlapping volume = maxZ of planeE
        overlapBox(6)=box1(6);
    end

end


%Using box2 as reference get the overlapping section in Y
%box(3) min value of Y
%box(4) max value of Y
if box1(4)<=box2(3) ||  box1(3) >=box2(4) %if maxY of plane E is less or equal than minY of ref. plane, or if minY of plane E is greater or equal than maxY of ref. plane, make minY and maxY of overlapping volume =0

    overlapBox(3) = 0;
    overlapBox(4) = 0;

else

    if box1(3)<= box2(3) %if minY of planeE is less or equal than minY of the reference plane, make minY of overlapping volume = minY of ref. plane
        overlapBox(3)=box2(3);
    else %if minY of planeE is greater than minY of the reference plane, make minY of overlapping volume = minY of planeE
        overlapBox(3)=box1(3);
    end

    if box1(4)>= box2(4) %if maxY of planeE is greater or equal than maxY of the reference plane, make maxY of overlapping volume = minY of ref. plane
        overlapBox(4)=box2(4);
    else %if maxY of planeE is less than maxY of the reference plane, make maxY of overlapping volume = maxY of planeE
        overlapBox(4)=box1(4);
    end
end

%Using box2 as reference get the overlapping section in X
%box(1) min value of X
%box(2) max value of X
if box1(2)<=box2(1) ||  box1(1) >=box2(2) %if maxX of plane E is less or equal than minX of ref. plane, or if minX of plane E is greater or equal than maxX of ref. plane, make minX and maxX of overlapping volume =0

    overlapBox(1) = 0;
    overlapBox(2) = 0;

else

    if box1(1)<= box2(1) %if minX of planeE is less or equal than minX of the reference plane, make minX of overlapping volume = minX of ref. plane
        overlapBox(1)=box2(1);
    else %if minX of planeE is greater than minX of the reference plane, make minX of overlapping volume = minX of planeE
        overlapBox(1)=box1(1);
    end

    if box1(2)>= box2(2) %if maxX of planeE is greater or equal than maxX of the reference plane, make maxX of overlapping volume = minX of ref. plane
        overlapBox(2)=box2(2);
    else %if maxX of planeE is less than maxX of the reference plane, make maxX of overlapping volume = maxX of planeE
        overlapBox(2)=box1(2);
    end
end

%Calculate volume of overlaping box
volOvBox = (overlapBox(2)-overlapBox(1)) * (overlapBox(4)-overlapBox(3)) * (overlapBox(6)-overlapBox(5));

%Calculate volume of reference box
volRefBox = (box2(2)-box2(1)) * (box2(4)-box2(3)) * (box2(6)-box2(5));

pvol = volOvBox/volRefBox;

end