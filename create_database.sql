USE [master]
GO

/****** Object:  Database [SophosLogging]    Script Date: 7/14/2018 2:05:15 PM ******/
CREATE DATABASE [SophosLogging]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'SophosLogging', FILENAME = N'D:\SQLData\SophosLogging.mdf' , SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'SophosLogging_log', FILENAME = N'D:\SQLData\SophosLogging_log.ldf' , SIZE = 11264KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

ALTER DATABASE [SophosLogging] SET COMPATIBILITY_LEVEL = 100
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
    EXEC [SophosLogging].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [SophosLogging] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [SophosLogging] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [SophosLogging] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [SophosLogging] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [SophosLogging] SET ARITHABORT OFF 
GO

ALTER DATABASE [SophosLogging] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [SophosLogging] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [SophosLogging] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [SophosLogging] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [SophosLogging] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [SophosLogging] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [SophosLogging] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [SophosLogging] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [SophosLogging] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [SophosLogging] SET  DISABLE_BROKER 
GO

ALTER DATABASE [SophosLogging] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [SophosLogging] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [SophosLogging] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [SophosLogging] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [SophosLogging] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [SophosLogging] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [SophosLogging] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [SophosLogging] SET RECOVERY SIMPLE 
GO

ALTER DATABASE [SophosLogging] SET  MULTI_USER 
GO

ALTER DATABASE [SophosLogging] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [SophosLogging] SET DB_CHAINING OFF 
GO

ALTER DATABASE [SophosLogging] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [SophosLogging] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO

ALTER DATABASE [SophosLogging] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [SophosLogging] SET  READ_WRITE 
GO


USE [SophosLogging]
GO

/****** Object:  Table [dbo].[tblAlerts]    Script Date: 7/14/2018 2:06:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblAlerts]
(
    [CustomerId] [int] NOT NULL,
    [Id] [uniqueidentifier] NOT NULL,
    [Location] [nvarchar](255) NOT NULL,
    [Severity] [nvarchar](50) NOT NULL,
    [AlertDate] [datetime] NOT NULL,
    [DataEndpointId] [uniqueidentifier] NULL,
    [DataEndpointPlatform] [nvarchar](255) NULL,
    [AlertType] [nvarchar](255) NULL,
    [AlertSource] [nvarchar](255) NULL,
    [AlertDescription] [nvarchar](max) NULL,
    CONSTRAINT [PK_CustomerId] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


USE [SophosLogging]
GO

/****** Object:  Table [dbo].[tblCustomers]    Script Date: 7/14/2018 2:06:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblCustomers]
(
    [CustomerId] [int] NOT NULL,
    [CustomerName] [nvarchar](max) NULL,
    [ApiKey] [nvarchar](max) NULL,
    [ApiKeySalt] [nvarchar](max) NULL,
    [ApiAuthorization] [nvarchar](max) NULL,
    [ApiAuthorizationSalt] [nvarchar](max) NULL,
    [LastSync] [datetime] NULL,
    [Status] [bit] NULL,
    [StatusMessage] [nvarchar](255) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


USE [SophosLogging]
GO

/****** Object:  Table [dbo].[tblEndpoints]    Script Date: 7/14/2018 2:07:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblEndpoints]
(
    [CustomerId] [int] NOT NULL,
    [Id] [uniqueidentifier] NOT NULL,
    [Name] [nvarchar](255) NULL,
    [AssignedProducts] [nvarchar](max) NULL,
    [EndpointType] [nvarchar](255) NULL,
    [LastUser] [nvarchar](255) NULL,
    [LastActivity] [datetime] NULL,
    [InfoPlatform] [nvarchar](255) NULL,
    [InfoIsInDomain] [bit] NULL,
    [InfoDomainName] [nvarchar](255) NULL,
    [InfoIpAddresses] [nvarchar](255) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


USE [SophosLogging]
GO

/****** Object:  Table [dbo].[tblEvents]    Script Date: 7/14/2018 2:07:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblEvents]
(
    [CustomerId] [int] NOT NULL,
    [Id] [uniqueidentifier] NOT NULL,
    [Location] [nvarchar](255) NULL,
    [Severity] [nvarchar](50) NULL,
    [EventDate] [datetime] NULL,
    [EventSource] [nvarchar](255) NULL,
    [EventType] [nvarchar](255) NULL,
    [EventName] [nvarchar](max) NULL,
    [EventGroup] [nvarchar](50) NULL,
    CONSTRAINT [PK_EventsCustomerId] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


