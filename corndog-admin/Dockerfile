FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY corndog-dotnet.csproj .
RUN dotnet restore
COPY src/ ./src/
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
RUN mkdir -p /exports /app/data

COPY --from=build /app/publish .

ARG DD_GIT_REPOSITORY_URL
ARG DD_GIT_COMMIT_SHA
ENV DD_GIT_REPOSITORY_URL=${DD_GIT_REPOSITORY_URL}
ENV DD_GIT_COMMIT_SHA=${DD_GIT_COMMIT_SHA}

ENV CORECLR_ENABLE_PROFILING=1
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV DD_DOTNET_TRACER_HOME=/app/datadog

EXPOSE 80
ENTRYPOINT ["dotnet", "corndog-dotnet.dll"]
