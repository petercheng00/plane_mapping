function centroid = getCentroid(X, Y, Z)

%Computes the centroid pf points in X,Y and Z

centroid=[sum(X)/size(X,2) sum(Y)/size(Y,2) sum(Z)/size(Z,2)];

end