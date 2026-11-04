FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files to restore dependencies
COPY ["backend/WebApi/WebApi.csproj", "WebApi/"]
COPY ["backend/Application/Application.csproj", "Application/"]
COPY ["backend/Domain/Domain.csproj", "Domain/"]
COPY ["backend/Infrastructure/Infrastructure.csproj", "Infrastructure/"]
RUN dotnet restore "WebApi/WebApi.csproj"

# Copy the rest of the backend source code
COPY backend/ .
WORKDIR "/src/WebApi"
FROM build AS publish
RUN dotnet publish "WebApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
RUN apt-get update \
    && apt-get install -y --no-install-recommends chromium libreoffice-writer fonts-liberation fonts-noto-core \
    && rm -rf /var/lib/apt/lists/*
ENV Flow1__Contracts__BrowserExecutablePath=/usr/bin/chromium \
    Flow1__Contracts__DisableBrowserSandbox=true
WORKDIR /app
COPY --from=publish /app/publish .
RUN mkdir -p /etc/fonts/conf.d && printf '<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">\n<fontconfig>\n <match target="pattern"><test name="family" compare="eq"><string>Times New Roman</string></test><edit name="family" mode="prepend" binding="strong"><string>Noto Serif</string></edit></match>\n <match target="pattern"><test name="family" compare="eq"><string>Arial</string></test><edit name="family" mode="prepend" binding="strong"><string>Noto Sans</string></edit></match>\n <match target="pattern"><test name="family" compare="eq"><string>Calibri</string></test><edit name="family" mode="prepend" binding="strong"><string>Noto Sans</string></edit></match>\n</fontconfig>\n' > /etc/fonts/conf.d/99-flow1-vietnamese.conf
ENTRYPOINT ["dotnet", "WebApi.dll"]
