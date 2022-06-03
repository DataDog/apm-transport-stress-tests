FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY ./MockAgent ./
RUN dotnet restore
RUN dotnet publish -c Release -f net6.0 -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
COPY --from=build /app/out .

RUN mkdir /var/run/datadog; \
    chmod -R a+rwX /var/run/datadog

EXPOSE 9126/tcp
EXPOSE 9125/udp

CMD ["dotnet", "MockAgent.dll"]