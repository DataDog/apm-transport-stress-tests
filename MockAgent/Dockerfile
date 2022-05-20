FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY . ./
RUN dotnet restore
RUN dotnet publish -c Release -f net6.0 -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
COPY --from=build /app/out .

CMD ["dotnet", "MockAgent.dll"]