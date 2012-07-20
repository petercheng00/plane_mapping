function triangles = earClipping(plane)
    %we want a plane with vertices in clockwise order. If following
    %convention, normal should be pointing upwards as well.
    vertices = plane.vertices;
    triangles = [];
    curIndex = 0;
    curIterations = 1;
    
    
    while(size(vertices,1) > 0)
        if size(vertices,1) == 3
            t.vertices = [vertices(1,:); vertices(2,:); vertices(3,:)];
            triangles = [triangles, t];
            vertices = [];
        else
            if (curIterations > size(vertices,1))
                disp (['Giving up after ', num2str(curIterations), ' attempts ', num2str(size(vertices, 1)), ' remaining vertices']);
                t.vertices = [vertices(1,:); vertices(2,:); vertices(3,:)];
                triangles = [triangles, t];
                vertices = [vertices(1,:); vertices(3:end,:)];
                curIterations = 0;
                continue;
            end
            
            
            curIndex = mod((curIndex + 1), size(vertices, 1));
            if curIndex == 0
                curIndex = size(vertices,1);
            end
            prevIndex = curIndex - 1;
            if prevIndex == 0
                prevIndex = size(vertices,1);
            end
            nextIndex = curIndex + 1;
            if nextIndex == size(vertices, 1) + 1;
                nextIndex = 1;
            end
            
            
            
            numInside = 0;
            for i = 1:size(vertices,1)
                if (i == prevIndex) || (i == curIndex) || (i == nextIndex)
                    continue;
                end
                baryCentric = calculateBaryCentricCoords(vertices(i,:), vertices(prevIndex,:), vertices(curIndex,:), vertices(nextIndex,:));
                if baryCentric(1) > 0 && baryCentric(1) < 1 && baryCentric(2) > 0 && baryCentric(2) < 1 && baryCentric(3) > 0 && baryCentric(3) < 1
                    numInside = numInside + 1;
                end
            end
            
            v1 = vertices(curIndex,:) - vertices(prevIndex,:);
            v2 = vertices(nextIndex,:) - vertices(curIndex,:);
            crossV = cross(v1,v2);
            if numInside == 0 && crossV(3) < 0
                t.vertices = [vertices(prevIndex,:); vertices(curIndex,:); vertices(nextIndex,:)];
                triangles = [triangles, t];
                vertices = [vertices(1:curIndex-1,:); vertices(curIndex+1:end,:)];
                curIterations = 0;
            else
                curIterations = curIterations + 1;
            end
        end
    end
end
            
        
function coords = calculateBaryCentricCoords(in, v1, v2, v3)
	x = in(1); 
	y = in(2); 

	xa = v1(1); 
	ya = v1(2); 

	xb = v2(1); 
	yb = v2(2); 

	xc = v3(1); 
	yc = v3(2); 

	gamma = ((ya-yb)*x + (xb-xa)*y + xa*yb - xb*ya)  /  ((ya-yb)*xc +(xb-xa)*yc + xa*yb - xb*ya);
	beta = ((ya-yc)*x + (xc-xa)*y + xa*yc - xc*ya)  /  ((ya-yc)*xb + (xc-xa)*yb + xa*yc - xc*ya);
	alpha = 1- beta - gamma;

	coords = [gamma, beta, alpha]; 
end