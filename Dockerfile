FROM julia:1.6.1

RUN julia -e 'using Pkg; Pkg.add("AWSClusterManagers")'
COPY src/AWSClusterManagersDemo.jl .

CMD ["julia", "-LAWSClusterManagersDemo.jl", "-e main()"]
