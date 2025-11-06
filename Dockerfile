# builds our image using dotnet's sdk
FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
WORKDIR /source
COPY . ./webapp/
WORKDIR /source/webapp

EXPOSE 80

#Datadog
RUN apt-get update && apt-get install -y wget curl tar jq && \
    # Obtener la tag de la release latest
    LATEST=$(curl -s https://api.github.com/repos/DataDog/dd-trace-dotnet/releases/latest | jq -r .tag_name) && \
    echo "Baixando Datadog .NET Tracer versão ${LATEST}" && \
    wget -O /tmp/datadog-dotnet-apm.tar.gz "https://github.com/DataDog/dd-trace-dotnet/releases/download/${LATEST}/datadog-dotnet-apm-${LATEST#v}.tar.gz" && \
    mkdir -p /opt/datadog && \
    tar -xzf /tmp/datadog-dotnet-apm.tar.gz -C /opt/datadog && \
    rm /tmp/datadog-dotnet-apm.tar.gz && \
    

# Variables de entorno Datadog
ENV CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8} \
    CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so \
    DD_DOTNET_TRACER_HOME=/opt/datadog \
    DD_ENV=lab \
    DD_VERSION=1.0 \
    DD_LOGS_INJECTION=true \
    DD_RUNTIME_METRICS_ENABLED=true

RUN dotnet restore
RUN dotnet publish -c release -o /app --no-restore

# runs it using aspnet runtime
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
WORKDIR /app
COPY --from=build /app ./
ENTRYPOINT ["dotnet", "webapp.dll"]
