FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -f net6.0 -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
COPY --from=build /app/out .

RUN mkdir -p /var/log/datadog/dotnet
RUN chmod a+rwx /var/log/datadog/dotnet

RUN mkdir -p /signals
RUN chmod a+rwx /signals
RUN echo "pls" > /signals/waiting.txt

CMD ["dotnet", "Spammer.Dotnet.dll"]
