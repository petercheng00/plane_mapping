function box = getBoundingBox(plane)

box(1)=min(plane.x);
box(2)=max(plane.x);
box(3)=min(plane.y);
box(4)=max(plane.y);
box(5)=min(plane.z);
box(6)=max(plane.z);

end