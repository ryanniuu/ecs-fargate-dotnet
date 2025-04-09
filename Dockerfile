FROM mcr.microsoft.com/dotnet/samples:latest

# Install the ADOT Collector
COPY --from=amazon/aws-otel-collector:latest /aws-otel-collector /aws-otel-collector

# Copy application files
WORKDIR /app
COPY . .

# Set environment variables for ADOT
ENV OTEL_RESOURCE_ATTRIBUTES=service.name=definitiv-app
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
ENV OTEL_TRACES_SAMPLER=always_on

EXPOSE 80
ENTRYPOINT ["dotnet", "run"]