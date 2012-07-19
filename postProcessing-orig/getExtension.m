function extension = getExtension(X, Y, Z)

%Compute extension of a wall defines by delimiting points in X, Y and Z

%Get pointer to min value of Z 
pointer=find(Z==min(Z));

%Among those points with minZ, get the one with minY
pointerMinY=pointer(find(Y(pointer)==min(Y(pointer))));

%Among those points with minZ, get the one with maxY
pointerMaxY=pointer(find(Y(pointer)==max(Y(pointer))));

p1=[X(pointerMinY) Y(pointerMinY) Z(pointerMinY)];
p2=[X(pointerMaxY) Y(pointerMaxY) Z(pointerMaxY)];

extension = getDistance(p1,p2);

end