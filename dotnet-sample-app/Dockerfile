FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /app
COPY . ./
RUN dotnet publish *.csproj -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY . ./
ENV AWS_REGION=ap-southeast-2
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel:4317
COPY --from=build-env /app/out .
ENTRYPOINT ["dotnet", "dotnet-sample-app.dll"]
  
