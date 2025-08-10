#!/bin/bash

echo "Medallion Architecture MVP - Simple Docker Execution"
echo "========================================================"

echo "Building Docker image..."
docker build -t medallion-product-mvp .

if [ $? -ne 0 ]; then
    echo "Docker build failed"
    exit 1
fi

echo "Build successful!"
echo ""
echo "Running medallion architecture pipeline..."
docker run --rm medallion-product-mvp

echo ""
echo "To query results interactively:"
echo "   docker run --rm -it medallion-product-mvp bash"
echo ""
echo "To persist database locally:"
echo "   docker run --rm -v \"\$(pwd)/target:/app/target\" medallion-product-mvp"
