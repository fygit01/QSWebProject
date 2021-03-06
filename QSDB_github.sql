USE [master]
GO
/****** Object:  Database [QSDB]    Script Date: 2017/9/21 19:17:37 ******/
CREATE DATABASE [QSDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'QSDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\QSDB.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'QSDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\QSDB_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [QSDB] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [QSDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [QSDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [QSDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [QSDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [QSDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [QSDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [QSDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [QSDB] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [QSDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [QSDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [QSDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [QSDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [QSDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [QSDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [QSDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [QSDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [QSDB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [QSDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [QSDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [QSDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [QSDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [QSDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [QSDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [QSDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [QSDB] SET RECOVERY FULL 
GO
ALTER DATABASE [QSDB] SET  MULTI_USER 
GO
ALTER DATABASE [QSDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [QSDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [QSDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [QSDB] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'QSDB', N'ON'
GO
USE [QSDB]
GO
/****** Object:  StoredProcedure [dbo].[feedback_change_proc]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[feedback_change_proc] as
	begin

		DECLARE @currentTime DateTime, @tomorrow DateTime, @realEndTime DateTime
		DECLARE @AWAIT INT, @UNDERWAY INT, @CLOSED INT

		--创建Feedback临时表，存储那些需要改变状态的反馈记录
		CREATE TABLE #Temp(
			[FeedbackId] [int] NOT NULL,
			[FeedbackName] [varchar](64) NULL,
			[StartTime] [datetime] NULL,
			[EndTime] [datetime] NULL,
			[Status] [int] NULL,
			[CreateTime] [datetime] NULL
		)

		SET @currentTime = GETDATE()
		SET @tomorrow = dateadd(day, 1, getdate())
		--Await = -1, Underway = 1, Closed = 0
		SET @AWAIT = -1
		SET @UNDERWAY = 1
		SET @CLOSED = 0
		
		UPDATE  Feedback SET Status = @UNDERWAY WHERE FeedbackId in(

			SELECT FeedbackId
			FROM Feedback 
			WHERE Status = @AWAIT AND StartTime <= @currentTime 
		)

		UPDATE  Feedback SET Status = @CLOSED WHERE FeedbackId in(

			SELECT FeedbackId
			FROM Feedback 
			WHERE (Status = @AWAIT OR Status = @UNDERWAY) AND dateadd(day, 1, EndTime) <= @currentTime
		)

	end;


GO
/****** Object:  StoredProcedure [dbo].[log_user_login]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Josephus>
-- Create date: <2015-01-30>
-- Description:	<存储用户登录的信息>
-- =============================================
CREATE PROCEDURE [dbo].[log_user_login]
	(
	@UserId int,
	@UserName nvarchar(32),
	@Ip nvarchar(50),
	@ComputerName nvarchar(50),
	@Platform nvarchar(50),
    @UserAgent nvarchar(500),
	@Type nvarchar(50)
	)
AS
	BEGIN TRANSACTION

    INSERT INTO LoginLog([UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (
	@UserId, @UserName, @Ip, @ComputerName, GETDATE(), @Platform, @UserAgent, @Type)

    IF @@ERROR <> 0    
    BEGIN
        ROLLBACK TRANSACTION        
    END        
        COMMIT TRANSACTION



GO
/****** Object:  StoredProcedure [dbo].[update_socreofbook]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[update_socreofbook] (@id bigint, @status int, @score decimal(18,1))
as
begin
if(@status = 1)
begin
	update Book set Wish = Wish + 1 where BookId = @id
	return
end

declare @total decimal(18,1), @num int, @result decimal(18,1), @i int, @j int
select @total = Grade, @num = EvaluateTimes from Book
where BookId = @id
--Already = 3, Wish = 1, Reading = 2
print('inproce: (total)' + cast (@total as varchar(20)) + ' (evaluatetimes)'+cast (@num as varchar(20)) + ' score'+cast (@score as varchar(20)))
set @result = (@total*@num + @score)/(@num + 1)
print(@result)
if(@status = 2)
begin
	set @i = 1
	set @j = 0
end
else
begin
	set @i = 0
	set @j = 1
end
update Book set Grade = @result, EvaluateTimes = EvaluateTimes + 1, Reading = Reading + @i, Already = Already + @j
where BookId = @id
end;


GO
/****** Object:  Table [dbo].[Article]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Article](
	[ArticleId] [bigint] IDENTITY(1,1) NOT NULL,
	[ArticleTitle] [nvarchar](100) NULL,
	[Category] [nvarchar](50) NULL,
	[IsTop] [bit] NULL,
	[ArticleContent] [nvarchar](max) NULL,
	[ViewTimes] [int] NULL,
	[CommentNum] [int] NULL,
	[ArticleTags] [nvarchar](50) NULL,
	[CreateTime] [datetime] NULL,
	[ThumbPath] [nvarchar](200) NULL,
 CONSTRAINT [PK_Article] PRIMARY KEY CLUSTERED 
(
	[ArticleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ArticleComment]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ArticleComment](
	[CommentId] [bigint] IDENTITY(1,1) NOT NULL,
	[UpId] [bigint] NULL,
	[NickName] [nvarchar](32) NULL,
	[Email] [varchar](64) NULL,
	[Content] [nvarchar](1024) NULL,
	[CreateTime] [datetime] NULL,
	[ArticleId] [bigint] NULL,
	[IsMember] [int] NULL,
	[UniqueKey] [nvarchar](50) NULL,
 CONSTRAINT [PK_ArticleComment] PRIMARY KEY CLUSTERED 
(
	[CommentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Atlas]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Atlas](
	[AtlasId] [uniqueidentifier] NOT NULL,
	[AtlasName] [nvarchar](255) NULL,
	[ThumbPath] [nvarchar](255) NULL,
	[AtlasPath] [nvarchar](255) NULL,
	[Remark] [nvarchar](500) NULL,
	[Hits] [int] NULL,
	[CommentNum] [int] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_Atlas_1] PRIMARY KEY CLUSTERED 
(
	[AtlasId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Book]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Book](
	[BookId] [bigint] IDENTITY(1,1) NOT NULL,
	[BookName] [nvarchar](50) NULL,
	[Remark] [nvarchar](128) NULL,
	[ThumbPath] [nvarchar](200) NULL,
	[Category] [nvarchar](50) NULL,
	[Author] [nvarchar](20) NULL,
	[Press] [nvarchar](50) NULL,
	[PageNum] [int] NULL,
	[Grade] [decimal](18, 1) NULL,
	[EvaluateTimes] [int] NULL,
	[Hits] [int] NULL,
	[HasResource] [bit] NULL,
	[ResourcePath] [nvarchar](200) NULL,
	[BookDescribing] [nvarchar](max) NULL,
	[AuthorDepict] [nvarchar](max) NULL,
	[CommentNum] [int] NULL,
	[CreateTime] [datetime] NULL,
	[PublishedTime] [nvarchar](15) NULL,
	[CoverPath] [nvarchar](200) NULL,
	[Already] [int] NULL,
	[Wish] [int] NULL,
	[Reading] [int] NULL,
 CONSTRAINT [PK_Book] PRIMARY KEY CLUSTERED 
(
	[BookId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BookComment]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BookComment](
	[CommentId] [bigint] IDENTITY(1,1) NOT NULL,
	[UpId] [bigint] NULL,
	[NickName] [nvarchar](32) NULL,
	[Email] [varchar](64) NULL,
	[Content] [nvarchar](1024) NULL,
	[CreateTime] [datetime] NULL,
	[BookId] [bigint] NULL,
	[IsMember] [int] NULL,
	[UniqueKey] [nvarchar](50) NULL,
	[Score] [decimal](18, 1) NULL,
	[ReadStatus] [int] NULL,
 CONSTRAINT [PK_BookComment] PRIMARY KEY CLUSTERED 
(
	[CommentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FbDocument]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FbDocument](
	[DocumentId] [uniqueidentifier] NOT NULL,
	[DocumentName] [nvarchar](512) NULL,
	[DocumentUrl] [nvarchar](max) NULL,
	[UploaderId] [int] NOT NULL,
	[UploadDate] [datetime] NOT NULL,
	[FeedbackId] [int] NOT NULL,
 CONSTRAINT [PK_Feedback] PRIMARY KEY CLUSTERED 
(
	[DocumentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Feedback]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Feedback](
	[FeedbackId] [int] IDENTITY(1,1) NOT NULL,
	[FeedbackName] [varchar](64) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Status] [int] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_Feedback_1] PRIMARY KEY CLUSTERED 
(
	[FeedbackId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Log]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Log](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NOT NULL,
	[Thread] [varchar](255) NOT NULL,
	[Level] [varchar](50) NOT NULL,
	[Logger] [varchar](255) NOT NULL,
	[Message] [varchar](4000) NOT NULL,
	[Exception] [varchar](8000) NULL,
 CONSTRAINT [PK_Log] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LoginLog]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoginLog](
	[LoginLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[UserName] [nvarchar](32) NULL,
	[IP] [nvarchar](50) NOT NULL,
	[ComputerName] [nvarchar](50) NULL,
	[LoginTime] [datetime] NOT NULL,
	[Platform] [nvarchar](50) NULL,
	[UserAgent] [nvarchar](500) NULL,
	[Type] [nvarchar](50) NULL,
 CONSTRAINT [PK__LoginLog__D42E7AEC2671C313] PRIMARY KEY CLUSTERED 
(
	[LoginLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Message]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Message](
	[MId] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](225) NULL,
	[Context] [nvarchar](max) NULL,
	[Appendix] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL,
	[CreateTime] [datetime] NULL,
	[EditTime] [datetime] NULL,
 CONSTRAINT [PK_Message] PRIMARY KEY CLUSTERED 
(
	[MId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MyMessage]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MyMessage](
	[MyId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[MId] [bigint] NOT NULL,
	[Status] [bit] NULL,
	[RecentTime] [datetime] NULL,
 CONSTRAINT [PK_MyMessage] PRIMARY KEY CLUSTERED 
(
	[MyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[News]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[News](
	[NewsId] [bigint] IDENTITY(1,1) NOT NULL,
	[NewsTitle] [nvarchar](100) NOT NULL,
	[Category] [nvarchar](50) NULL,
	[IsTop] [bit] NULL,
	[NewsContent] [nvarchar](max) NOT NULL,
	[ViewTimes] [int] NULL,
	[CommentNum] [int] NULL,
	[NewsTags] [nvarchar](50) NULL,
	[CreateTime] [datetime] NULL,
	[ThumbPath] [nvarchar](200) NULL,
 CONSTRAINT [PK_News] PRIMARY KEY CLUSTERED 
(
	[NewsId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[NewsComment]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NewsComment](
	[CommentId] [bigint] IDENTITY(1,1) NOT NULL,
	[UpId] [bigint] NULL,
	[NickName] [nvarchar](32) NULL,
	[Email] [varchar](64) NULL,
	[Content] [nvarchar](1024) NULL,
	[CreateTime] [datetime] NULL,
	[NewsId] [bigint] NULL,
	[IsMember] [int] NULL,
	[UniqueKey] [nvarchar](50) NULL,
 CONSTRAINT [PK_NewsComment] PRIMARY KEY CLUSTERED 
(
	[CommentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Photo]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Photo](
	[PhotoId] [uniqueidentifier] NOT NULL,
	[AtlasId] [uniqueidentifier] NULL,
	[PhotoName] [nvarchar](255) NULL,
	[PhotoTags] [nvarchar](50) NULL,
	[ThumbPath] [nvarchar](255) NULL,
	[PhotoPath] [nvarchar](255) NULL,
	[Remark] [nvarchar](500) NULL,
	[Hits] [int] NULL,
	[CommentNum] [int] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_Photo_1] PRIMARY KEY CLUSTERED 
(
	[PhotoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[RecentActivity]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecentActivity](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](100) NULL,
	[StartTime] [datetime] NULL,
	[Address] [nvarchar](256) NULL,
	[Content] [nvarchar](1024) NULL,
	[Status] [bit] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_RecentActivity] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Reservation]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Reservation](
	[RId] [int] IDENTITY(1,1) NOT NULL,
	[SubscriberName] [nvarchar](32) NOT NULL,
	[StuNumber] [varchar](32) NOT NULL,
	[Gender] [int] NULL,
	[Age] [int] NULL,
	[Professional] [nvarchar](64) NOT NULL,
	[Phone] [varchar](32) NOT NULL,
	[Email] [varchar](64) NULL,
	[Past] [nvarchar](128) NULL,
	[Experience] [nvarchar](128) NULL,
	[Dealtime] [datetime] NOT NULL,
	[Situation] [nvarchar](2000) NULL,
	[Createtime] [datetime] NULL,
	[State] [int] NULL,
 CONSTRAINT [PK_Reservation] PRIMARY KEY CLUSTERED 
(
	[RId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Suggestion]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Suggestion](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NickName] [nvarchar](32) NULL,
	[Email] [varchar](64) NULL,
	[Content] [nvarchar](1024) NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_Suggestion] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tag]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tag](
	[TagId] [int] IDENTITY(1,1) NOT NULL,
	[TagName] [nvarchar](50) NULL,
	[TagEnglish] [nvarchar](50) NULL,
	[TagDescription] [nvarchar](500) NULL,
	[Belong] [int] NULL,
	[TagSum] [bigint] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_Tag] PRIMARY KEY CLUSTERED 
(
	[TagId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[User]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[User](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](32) NULL,
	[Password] [varchar](32) NOT NULL,
	[RealName] [nvarchar](32) NOT NULL,
	[StuNumber] [varchar](32) NOT NULL,
	[Identification] [nvarchar](64) NULL,
	[Gender] [int] NULL,
	[Phone] [varchar](32) NULL,
	[Email] [varchar](64) NULL,
	[PhotoUrl] [nvarchar](256) NULL,
	[About] [ntext] NULL,
	[PersonalPage] [varchar](64) NULL,
	[State] [int] NULL,
	[Roles] [nvarchar](100) NULL,
 CONSTRAINT [PK_User_1] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Video]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Video](
	[VideoId] [bigint] IDENTITY(1,1) NOT NULL,
	[VideoName] [nvarchar](50) NULL,
	[ThumbPath] [nvarchar](255) NULL,
	[VideoPath] [nvarchar](255) NULL,
	[Remark] [nvarchar](512) NULL,
	[Hits] [int] NULL,
	[CommentNum] [int] NULL,
	[CreateTime] [datetime] NULL,
	[Category] [nvarchar](50) NULL,
	[ComesFrom] [nvarchar](100) NULL,
	[IsLocal] [bit] NULL,
	[Recommend] [bit] NULL,
 CONSTRAINT [PK_Video] PRIMARY KEY CLUSTERED 
(
	[VideoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[VideoComment]    Script Date: 2017/9/21 19:17:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VideoComment](
	[CommentId] [bigint] IDENTITY(1,1) NOT NULL,
	[UpId] [bigint] NULL,
	[NickName] [nvarchar](32) NULL,
	[Email] [varchar](64) NULL,
	[Content] [nvarchar](1024) NULL,
	[CreateTime] [datetime] NULL,
	[VideoId] [bigint] NULL,
	[IsMember] [int] NULL,
	[UniqueKey] [nvarchar](50) NULL,
 CONSTRAINT [PK_VideoComment] PRIMARY KEY CLUSTERED 
(
	[CommentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET IDENTITY_INSERT [dbo].[Article] ON 

INSERT [dbo].[Article] ([ArticleId], [ArticleTitle], [Category], [IsTop], [ArticleContent], [ViewTimes], [CommentNum], [ArticleTags], [CreateTime], [ThumbPath]) VALUES (1, N'刘翔退役：丧失如此可敬，以至于我们要花一生明白', N'wisdomlife', 0, N'<p>
	<em>来源于：壹心理 作者：卢悦</em>
</p>
<p>
	<br />
</p>
<p>
	刘翔退役了。在2012年伦敦奥运会之后，他从未参加过一次比赛。很难想象，已经销声匿迹两年多的他，在这些日子里承受着怎样的压力。
</p>
<p>
	他的压力来自两方面，一方面是来自官府，一方面来自民众。无论来自哪边，都出于一个动机：刘翔，作为一个唯一的可以在短跑领域可以和欧美非洲人种抗衡的亚洲人，他的存在，是一种证明：在人种上，我们是不输于其他人种的。
</p>
<p>
	这种人种的自卑，来自历史上，中国人的创伤。从霍元甲的时代开始，中国人似乎就开始被日本人质疑，被西洋人讽刺为“东亚病夫”。与之相应的是中国在世界的地位和被反复入侵与欺凌的各种伤痛。
</p>
<p>
	这种伤痛感，到今天依然可以在各种民粹主义的风潮中被反复咀嚼和代谢。比如拳击赛场，我们会经常看到中国的拳手，轻易KO来自泰国、日本、欧洲的选手。这依然可以成为新闻里的关键词而被广为传播。
</p>
<p>
	韩
国人可能要比中国人在这方面更欠缺：他们连粽子都要着急和中国人抢着申遗。而日本人则死死想要恢复旧日的荣光。韩国人是想证明自己是嫡传的，不是庶出的；
而日本人则想证明，老子侵华的那段历史没错；而中国人则根本不想谈及过去，就是想证明现在老子很牛，因为过去实在惨不忍睹。
</p>
<p>
	中国的经济崛起
了，似乎可以给中国找到一些自信；奥运会上的金牌霸主似乎还是不能满足大家的自恋。因为我们发现，我们可以在一些不起眼的小项目上速成，但却无法在一些关
键性的主流项目上获得成就。比如足球、短跑、篮球、网球。这些可以赢得巨量眼球的项目，我们一直都无法满足自恋。
</p>
<p>
	后来我们有了姚明、李娜、以及刘翔，他们的存在，可以让我们的自恋继续复活，可以让整个民族都乎有了一剂强心针。女排当年给整个民族的鼓舞超过那些奥运会那么多金牌给人的全能感的满足。
</p>
<p>
	刘翔做到了。他几乎被看成是民族英雄。但这个世间有一个公理：你拥有多大的权利就要承受多大的义务。
</p>
<p>
	他是如何承受义务的呢？引用一篇文章的内容：
</p>
<p>
	“2009年6月，距离刘翔第一次复出（上海国际田径黄金大奖赛）还有3个月时间，记者因一次特殊的采访，在上海莘庄训练基地见到了结束了上午训练的刘翔。
</p>
<p>
	当
时，刘翔刚刚经历第一次脚踝手术不到半年，正在咬牙承受高强度训练，北京奥运会退赛招致的责骂还沉沉压在这个年轻人身上，所以看上去刘翔并不开心，而基地
食堂里大部分运动员都“懂得”要自觉拉开与刘翔的距离，除了保障组几乎形影不离的一位高级后勤人员，刘翔“不太容易”找到可以随意聊天或倾诉的对象，更何
况他在基地的住处极为特殊，要进他的宿舍，需要领导批示专人带路，才能通过楼道里加焊出来的一道铁门——如果不是那间被厚厚窗帘挡住阳光的单人宿舍里还有
轻快的音乐作伴，记者很难将这个被隆重“收藏”的“神秘人物”，与5年前那个风一样冲过雅典奥林匹克竞技场终点线，然后喊出“中国有我”、“亚洲有我”的
意气风发的飞人联系起来。“
</p>
<p>
	“被装进套子的刘翔，尤其是受伤之后必须配合大家一起把自己装进套子的刘翔，就这样度过了自己职业生涯中的最后7年，难怪田管中心的工作人员现在说起刘翔，语气从崇拜者的激昂过渡到旁观者的不忍‘其实，他的自由度很小很小。’”
</p>
<p>
	现在很多文章都似乎都在把刘翔描绘为一个悲情人物。似乎他完全无法抵抗这种把他放入笼中的命运。
</p>
<p>
	那么问题出来了，为什么刘翔似乎像一个金丝笼里的鹦鹉一样，和姚明、李娜等人的命运如此不同？似乎她们的退役都是非常痛快的，而且似乎毫无牵绊。虽然也很痛苦，但似乎都没有如此漫长的痛苦的决定期。
</p>
<p>
	刘翔在退役后的采访中说，我终于可以重新成为一个人了。
</p>
<p>
	那么他之前过的是什么生活？非人的生活。那么他的自主权呢？是什么让他无法拒绝？
</p>
<p>
	我们如何面对丧失的？其实很简单，这和我们的拥有有关系。
</p>
<p>
	如果这个奶酪是我唯一的财产，而且一旦失去它，我也不知道到哪里寻找。那我一定很难放手。
</p>
<p>
	我大学的时候，曾给一个从美国来的理发师做翻译，她告诉<strong>我：在美国，最重要的是美国梦，美国梦不是发财梦，而是能实现自己的梦想。就算梦想没实现，最重要的是让自己开心。她很好奇，中国人如此热衷成为一种人。她说，每个人都有不可替代的独特。</strong>
</p>
<p>
	这句话对我影响很大。我很惊讶，一个美国的理发师可以有这样的价值观，而我们很多人都一直都生活在局中，蝇营狗苟，疲惫不堪。
</p>
<p>
	<strong>刘翔其实就是我们这个时代的象征：为了巨大无比的自恋，丧失了自我的主权。一旦我们的面子，我们的虚荣，我们对名利的追逐超过了对自我的珍视，就像刘翔那样，为了永无止境的速度，不断加量训练，直至跟腱断裂。</strong>
</p>
<p>
	有人说刘翔的问题是成王败寇的哲学对他的伤害。但我觉得这不只是哲学，更是一个依恋的问题。
</p>
<p>
	对一个婴儿来说，他这个世界上唯一和最重要的资源就是乳房或者奶瓶，没有它们，他的世界就是空。所以一旦饿了，他会拼尽全力地哭，有了奶会使出吃奶的劲儿来哭。而一旦他有了牙齿，就知道妈妈的奶不再是唯一的生命的来源，理论上，他可以离开妈妈而存在了。
</p>
<p>
	这也在我在《孙楠》一文中说过的：一个人需要有B计划。没有B计划的人生，就可能是在作死。因为这是和老天爷作对。一个试图用自己的世界来取代现实的世界，结果往往都是鸡蛋碰石头。
</p>
<p>
	我没有多说，为什么一个人只能一条道走到黑了，一个人没有选择，是因为他在精神上始终没有学会以母乳以外的方式活着，一直没有尝试着用自己的牙齿来进食。
</p>
<p>
	比
如一个一直都生活在相对封闭的大包大揽的体育圈子里的运动员，在某种程度上，他就和外界的交换工具，就是他的竞技，没有竞技，他什么都不是。其实这个状态
不只是中国有，有报道说，足球运动员退役后不能过正常生活的，比如像加斯科因那样酗酒、吸毒者大有人在。因为他们不知道除了他一直奋斗的一切以外，他可以
靠着什么活着。
</p>
<p>
	就像一个美女不知道除了她的美以外，还有什么值得她去活；一个大款不知道除了自己的钱以外，还有什么可以傲人的；一个官员不知道除了他的权力以外，还有什么可以赢得他人的尊敬。
</p>
<p>
	<strong>实际上，他们从小是被吓大的，他们发现如果没有他所努力的一切，他就可能失去了和这个世界的联系，就像一个婴儿总是恐惧妈妈会离开他。</strong>
</p>
<p>
	<strong>自
恋的问题其实就是母爱不足和父爱不够的问题，一个人无法在小时候从妈妈那里得到疼痛时候的慰藉，从爸爸那里获得胜利时候的骄傲的时候，他就会努力创造一个
可以给他回应的世界，那就是一个自恋的世界，在那里，竞技的世界就像是可以自然产生回馈的产爱机一样。这是这个世界唯一可以回馈他的。</strong>
</p>
<p>
	如果这一切对他如此重要，他又怎能离开？
</p>
<p>
	所以那些一生只爱一个人的人，并不是真正的“人”，因为他们还没有“牙齿”。一旦他们失去，就是永远的失去，他们不相信这个世界还有什么可以让他们活下去。因为在他们需要人的回应的时候，从未有人给他们足够和健康的回应。
</p>
<p>
	在这里，推荐大家看一个电影《香水》，看了这个电影，大家就会更深地理解我在说什么。
</p>
<p>
	一个拥有完整自我的人，永远都是有选择的人，就像姚明，他相信即使放弃了这么重要的一生都在努力的篮球，他依然可以很好地活着。就像李娜，她相信即使她没有职业了，也会有江山这样的暖男一直在她身边爱她。他们的人生还有很多选择，因为他们从未被奶瓶所控制。
</p>
<p>
	还是那句话，不成长，你就永远被你所需要的控制，而最终也会失去它。
</p>', 9, 1, NULL, CAST(0x0000A479000D6D2E AS DateTime), N'/Images/Articles/20150413/201504130048530426.jpg')
INSERT [dbo].[Article] ([ArticleId], [ArticleTitle], [Category], [IsTop], [ArticleContent], [ViewTimes], [CommentNum], [ArticleTags], [CreateTime], [ThumbPath]) VALUES (2, N'认识自己最好的办法就是看你喜欢谁', N'youth', 0, N'<p style="text-align:left;">
	<em>来源于：心灵咖啡网</em>
</p>
<p style="text-align:left;">
	<img src="/Attached/News/image/20150413/20150413005401_8780.jpg" alt="" />
</p>
<p style="text-align:left;">
	刻在德尔斐阿波罗神庙的三句箴言中最有名的一句是：“认识你自己”（Γνώθι 
σεαυτόν）。找工作需要认识自己，谈恋爱要认识自己，职业生涯发展需要认识自己。实现高效的工作、快乐的生活，都需要对自己有深度的了解才能够有所
针对的改进。那么，我们该如何认识自己呢？今天不谈心理测试，只介绍一个最简单的办法。
</p>
<p style="text-align:left;">
	真
正做到认识自己的方法，就是以人为镜。把与你工作互动最多的5位同事的名字写下来，你问自己最喜欢谁，最不喜欢谁，对于那个你最喜欢的人，你要开始找他很
可能不足的地方，而且这些不足很可能在你身上也有，你喜欢她就是因为有亲切感，因此这些特点很可能也在你身上。对于那个你最不喜欢的人，你要努力去找他的
优点在哪里，因为只要你能够找出他的优点，你就会慢慢开始接受他。
</p>
<p style="text-align:left;">
	<p style="text-align:left;">
		我们都是趋利避害的，喜欢的那些人不一定是他们身上有着我们向往的品质，也很有可能是对方和你具有一样的缺点，让你感觉找到了同类、伙伴，觉得安全所以才会去信赖和依附他们。
	</p>
	<p style="text-align:left;">
		武志红在《为何爱会伤人》里说，我们常以为，当看到一个人时，我们看到的是容貌、<a href="http://baike.psycofe.com/view/3939" target="_blank">气质</a>和神情。其实，这只是<a href="http://baike.psycofe.com/view/3713" target="_blank">意识</a>层面上的“看到”，潜意识层面上的“看到”更加关键，更加丰富，也更加重要。我们在“潜意识”层面的看到更多的是为了安全而发展出来的投射性的认同，这就会有了“物以类聚”的说法。
	</p>
	<p style="text-align:left;">
		以
我为例，我喜欢和做事干净利落，积极协作的人共事，但是有时候这样的人会把自己的活也抢过去了，你不知道他这样是太仗义还是没有考虑到项目负责人的主导
权，心里多少会有些芥蒂的。反观自己，其实我也是那种别人说一句“拜托”就会把活儿揽在身上、不会拒绝的人，这样不以成果、以关系为导向的行为只会更遭，
最后两边都不讨好。
	</p>
	<p style="text-align:left;">
		而我讨厌的类型是整天说大话却不见行动成果的人，反过来看自己，说实在的，我也会和好朋友说大话，也有好很多大话没实现，比如去年就说过要写“千字文”、要早睡，可是一周都没坚持下来，真是汗颜。
	</p>
	<p style="text-align:left;">
		我所讨厌的特点其实就在自己身上。但是，当你仔细观察一个人在说大话的时候，眼神很亮、充满激情、很有感染力，这不也是“说大话”人独特的地方吗？一个有激情、爱想象的人，试着学习去提升自己的行动力，学会把承诺一点点拆分成可行动的步骤，同样很值得信任。
	</p>
	<p style="text-align:left;">
		所以，认识自己的最佳方式就是在与人的互动中去省察自己，可以试着分析工作的时候在部门内部喜欢谁、不怎么喜欢谁，然后想想从他们身上折射了自己的什么特点，可以从他们身上学到什么。
	</p>
	<p style="text-align:left;">
		无论你是觉得和一些人特别合拍，还是对一些人怎么都看不顺眼，平常心对待。对于喜欢的人不过分痴迷，对于讨厌的人不一棍子打死，每个行为的背后都有原因，去感受、觉察、去分析以及包容，不妄下定论。
	</p>
	<p style="text-align:left;">
		在这样的方式中，我们既认识了自己，也实现了与外界和谐的相处。
	</p>
	<p style="text-align:left;">
		【一期一会】
	</p>
	<p style="text-align:left;">
		我们无可避免跟自己保持陌生，我们不明白自己，我们搞不清楚自己，我们的永恒判词是：“离每个人最远的，就是他自己。”──对于我们自己，我们不是‘知者’……
	</p>
	<p style="text-align:left;">
		——尼采
	</p>
</p>', 5, 0, NULL, CAST(0x0000A479000F1FEC AS DateTime), N'/Images/Articles/20150413/201504130055040222.jpg')
INSERT [dbo].[Article] ([ArticleId], [ArticleTitle], [Category], [IsTop], [ArticleContent], [ViewTimes], [CommentNum], [ArticleTags], [CreateTime], [ThumbPath]) VALUES (3, N'别让焦虑成为你追逐梦想的绊脚石！', N'youth', 0, N'你有没有过因为焦虑而优柔寡断、自我怀疑？开始一个新项目，或是想融入一个新的群体，心里会不会七上八下、忐忑不安甚至有些恐惧？参加徒步旅行俱乐
部、或是加入自愿组织在网上晒自己的约会档案、减肥、写博客、把自己的的爱好做成事业......这些事情看上去既有趣又有意义，你心生向往跃跃欲试，但
最终是不是还是为自己编了一堆理由放弃，只因为其中可能存在的风险？是不是做了无数研究但就是没法做出行动把想法变成现实？如果这是你，那么焦虑和过度谨
慎可能已经妨碍你追逐梦想、过上有意义且充实的生活。逃避只会恶性循环让你更加不自信，而开始行动则会建立正向回路让你自然而然减少焦虑。那么怎么开始
呢？以下的策略提供了一条向前进的路，为你开启追求理想生活的第一步！
<h4>
	不要坐等焦虑减轻！
</h4>
<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
焦虑植根于我们的天性之中，它不会自己减轻。人类的大脑生来就憎恶不确定性、不可预计性和变化，只是有些人天生焦虑易感性更高。然而当你顶着焦虑采取行动
朝着目标迈进时，大脑会重新评估，并告诉你其实不确定性也没有那么危险，这就是成功的第一步。随着时间的推移，慢慢地你会建立一种自我效能感，即使感到焦
虑，你也会认为自己有行动能力并且能够通过行动获得成功。
</p>
<h4>
	设立适合自己的、符合实际的目标！
</h4>
<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
我们都有不同的性格、脾气和喜好。并不是每个人都想成为律师、朋友成群、跑马拉松、瘦成闪电或者坐拥豪宅。焦虑让你觉得自己没有别人有天分、有竞争力，甚
至不像别人一样值得被爱。如果你不了解真正的自己，在设立目标时，你很有可能会仿照你的朋友甚至邻居，去做一些社会认可的事情或是满足他人的期望。这种情
况下设立的目标很难成为长期坚持的目标，尤其是那些你并非真正热爱的事情。与其总是想你“应该”做什么，不如换个角度想想你真正想要什么，说不定你是个有
创造力的人，或是想要生活工作平衡、想去旅行、活得更健康，又或者你只是想找个可心的人儿。不管你想要什么，想清楚，然后找到最容易的入手的事情行动起
来。把目标用具体的可量化的方式表达，比如：“下周散步三次，每次20分钟。”切记，不要想一步登天，一口吃成个胖子，另外达成目标最好是内部动机驱动，
而不是为了取悦他人。
</p>
<h4>
	信任过程！
</h4>
<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 马丁路德金说过:"信念，就是即使看不到长阶通向何方，却仍愿意迈出第一步。”<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
即使一开始没有,但只要你迈出了第一步,信念就会随之而来.做得越多,成功的可能性就越高,慢慢地你会相信自己,相信过程,相信世界。我的博客常常开始于
我完全不知道要写些什么的时候。我知道只要我有东西要分享,并真心诚意的想帮助读者,内容自然而然就会出现.很多作家都会告诉你,刚开始写作的时候，随着
焦虑慢慢减少，到最后只剩下故事和传递想法的纯真热情，这个时候你的想法和创造性地作品自然而然就出来了。这个道理同样适用于生活的其他方面，比如开始一
份新工作、新项目、新恋情或是新的投资项目。
</p>
<h4>
	不要小题大做
</h4>
<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
面对风险，焦虑的人习惯性地关注坏的结果，而面对负性结果时，他们也更倾向关注这个结果到底会坏到什么程度。他们会想，去约会如果遇到奇葩怎么办？万一我
看对了眼别人会不会再联络我？投资创业失败了怎么办？换工作投简历没有反馈怎么办？不换工作当前的状态又让自己痛苦不堪怎么办？这些结果都不是我们想要
的，但是他们到底有多糟呢？比罹患癌症更糟糕？还是比家人离世更糟糕？我相信答案一定是“不！”那么你能挺过去吗？你有应对的策略吗？或者等下次换个方式
再试试？我相信你可以的！焦虑让你过度高估了采取行动的风险，但是不是也该考虑考虑一直处在糟糕状况下的风险呢？时过境迁，回想当年，你是否会遗憾面对梦
想，你竟然试都没试就放弃了？
</p>
<h4>
	做自己的拉拉队长，而不是自我批评家！
</h4>
<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
追逐梦想是艰难的，沿途要面对无数不可避免的阻碍和失败。有些事情结果可能不那么完美，这时千万不要打击自己，给自己增加障碍。人生许多重要的成功都有些
运气的成分在里面。我们只能控制自己，不能左右他人和环境。你可以为自己辩护，也会因此而受到批评和打压，但是这并不意味着你做错了什么。大脑天生就关注
负性信息因为它的机制是以保护为中心，而不是提升为中心的。要克服这种偏差，你必须刻意关注事情的积极方面。认可自己的冒险行为、适应不安、或者当你想蜷
在家里沙发上什么都不做时，表现出来。你不能控制结果，但你可以鼓励自己在过程中付出的努力，这样你就能一直保持动力。<br />
<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 有了这些方法，你可以开始试着掌控焦虑，而不是让它掌控你。不能完全摆脱焦虑一点关系都没有（好像也不太可能）。即便如此，你还是可以选择向前进，采取结构化的行动，从而构建心理韧性和自信，为获得充实、有意义的生活创造可能性。<br />
<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 这很不容易，但是我相信值得一试！
</p>
<p>
	<br />
</p>
<p>
	原文来源：<a class="sa_blue" href="https://www.psychologytoday.com/blog/the-mindful-self-express/201503/dont-let-anxiety-hold-you-back-living-your-dreams" target="_blank">psychologytoday.com</a>
</p>', 7, 1, NULL, CAST(0x0000A47900107DD7 AS DateTime), N'/Images/Articles/20150413/201504130100026218.jpg')
INSERT [dbo].[Article] ([ArticleId], [ArticleTitle], [Category], [IsTop], [ArticleContent], [ViewTimes], [CommentNum], [ArticleTags], [CreateTime], [ThumbPath]) VALUES (4, N'我们是否高估了“当下”的力量？', N'youth', 0, N'<p>
	<span style="text-decoration:none;">（文/John Amodeo PhD，译/</span><a href="http://article.yeeyan.org/view/530502/449817" target="_blank">小雨沙沙1990</a><span style="text-decoration:none;">）来源心灵咖啡网</span>
</p>
<p>
	<img src="/Attached/News/image/20150413/20150413010201_5517.jpg" alt="" /><br />
<span style="text-decoration:none;"></span>
</p>
<p>
	这些天我们经常听到有人在宣讲珍惜当前的重要性，他们告诉我们，现在是实实在在的存在，如果我们此刻不在，那么我们就不是真正的存在。
</p>
<p>
	这一点对我来说意义重大。我时常发现自己被未来的一些想法分散精力，或者过去的一些经历在我脑海中重现，无济于事。
</p>
<p>
	<strong>活在当下能让我们更自由而充实地体会生活，这是件好事，但这也会产生阴暗面吗？就像任何规则或者说明，都会有它的局限，很容易误导他人。</strong>
</p>
<p>
	东拉西扯的想法，和我们的想法交织在一起，并不能让我们走得很远。我们经常会没有征兆地从一个想法偏离到另一个想法。一连串的联想让我们的思绪不用任何牵引就能飘到很远的地方。当和我们的伴侣吃晚餐的时候，也许我们下一秒就开始担心工作或金钱的事情。
</p>
<p>
	自
我责备的想法是让我们偏离当前的常见方式。我们或许会产生我们并不够好、不够聪明或者不够有吸引力这样的想法。我们也许注意到诸如“我怎么了？”或者“刚
才那段话自己真是口齿不清”或者“什么时候我能找到一段好感情？”这类的自言自语，一次又一次直接地将我们从当前剥离开来。
</p>
<p>
	冥想和正念的练习能给我们的思想提供指导；“放空心灵”的练习能够唤起我们内心轻柔的独白；“考虑，考虑”能将没用的想法去除，让我们的注意力重新回到我们的呼吸、身体还有当前。然而，要是我们将<a href="http://baike.psycofe.com/view/3713" target="_blank">意识</a>投注到我们的思想、担忧和碰巧体验到的感觉之上呢？不论我们正在经历什么，我们都能留在“当下”吗？
</p>
<p>
	<strong><span style="font-size:18px;">忠于我们的想法和感觉</span></strong>
</p>
<p>
	我
们被自己的想法分心这一事实并不意味着思考总是没有意义的，会有我们需要思考一些事情的时候——或许一个商业决定、一份退休计划或者如何向伴侣表达我们的
感情还有渴望。类似这些的思考，就是我们有意识地活在当下的一部分。冥想大师杰森·西弗提出了这样使人精神焕发的方法：
</p>
<p>
	<strong>我认为对于冥想的方式其实是和每个人的经历有关的，不需要太过复杂化，因为我们最终的目的是回归自然本真，以及抛下对于冥想的警觉</strong>……我听过很多人们关于他们冥想的报道，有的人会写一篇文章，或作一首曲子，或计划一个艺术项目或者重新装饰她的房子，事实上冥想是富有成效的。
</p>
<p>
	有精神质倾向的人们经常忽视此刻的感情的重要性。但其实如果我们认为活在当下就要将感情当做分心的东西，那我们就不是活在当下了。努力呆在某些不属于我们的地方会让我们脱离当前。正念是用于活在当下的练习，而不是试图将我们带入一个不同的时刻。
</p>
<p>
	要让我们的情感中留有空余，并给它们准备一个缓冲的区域，而不是通过暴怒或者责备评论去发泄。<strong>认为我们生活在当下，我们就能从思考深层真实的感情中获益匪浅。</strong>在最初的怒发冲冠中也许还包含有伤心，恐惧或者羞愧。我们能让我们在当前用一种方式将我们内心深处的感情浮现吗？正念思考并且分享我们此刻真实的感情能将我们和别人亲密地联系在一起。
</p>
<p>
	对一些人来说，活在当下也许是避免不舒服感情的微妙方式。不愉快的感情一出现，他们就努力迅速将注意力收回试图回到当前。但是他们永远达不到感情的最深处，因此情绪总是反反复复。
</p>
<p>
	<strong>就像一个受伤的孩子会大声要求被留意直到他的呼声被听到，我们的感情需要这种关注。</strong>当他受欢迎并且用一种温和的，关怀的方式被倾听的时候，他们往往就会过去。然后我们新的一刻就自由了，也就摆脱了有麻烦的情感。
</p>
<p>
	“活
在当下”是一个有帮助的提醒，能够让我们留意发生的一切。当感情，想法或者渴望产生的时候，我们能注意到，平和地对待，顺其自然。当我们让他们按照预定的
轨道行驶的时候，我们或许会注意到我们的头脑没有想法，而是以一种安静的、豁达的活力晒太阳。我们生活会有更多的平和和意义，因为我们为人类的经历腾出了
广阔的空间。
</p>', 13, 0, NULL, CAST(0x0000A479001110C8 AS DateTime), N'/Images/Articles/20150413/201504130102080167.jpg')
SET IDENTITY_INSERT [dbo].[Article] OFF
SET IDENTITY_INSERT [dbo].[ArticleComment] ON 

INSERT [dbo].[ArticleComment] ([CommentId], [UpId], [NickName], [Email], [Content], [CreateTime], [ArticleId], [IsMember], [UniqueKey]) VALUES (1, 0, N'[匿名用户]', N'guifaliao@gmail.com', N'哈哈哈哈哈哈哈', CAST(0x0000A6A201774DD6 AS DateTime), 1, 0, N'201610172246264193')
INSERT [dbo].[ArticleComment] ([CommentId], [UpId], [NickName], [Email], [Content], [CreateTime], [ArticleId], [IsMember], [UniqueKey]) VALUES (2, 0, N'周揭露', N'guifaliao@gmail.com', N'慰藉成谜，啥也不想ixiangxin，你相信吗？', CAST(0x0000A6A20177C8DC AS DateTime), 3, 0, N'201610172248114014')
SET IDENTITY_INSERT [dbo].[ArticleComment] OFF
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', N'知乎上一些奇葩的答案', N'/Images/Gallery/20150413/thumb_201504131134425115.jpg', NULL, N'转自电影工厂的微博', 12, 0, CAST(0x0000A47900BEB1D6 AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', N'诡异的心理学图片', N'/Images/Gallery/20150413/thumb_201504131233068685.jpg', NULL, N'说起考试，人们往往会皱起眉头，然而，有一种考试却很受欢迎，这就是心理测试。现在很多时尚杂志、新闻、网站都设立了心理测试专题，人们被这些涉及到爱情、婚姻、性格、事业、学业、人际关系等方面的测试所吸引。今天给大家带来9张心理测试图片大全，让你一眼看穿自己。快来测试看看吧。', 9, 0, CAST(0x0000A47900CEBF7C AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'f08c10f2-21e2-4b81-9f32-a47900d3d431', N'插画欣赏', N'/Images/Gallery/20150413/thumb_201504131251324036.jpg', NULL, N'摘自：花瓣网（huaban.com）采集用户：狼孩儿wolfchild', 22, 0, CAST(0x0000A47900D3D430 AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'94fe8de6-8172-42c6-be6e-a47900d98478', N'A到Z的故事', N'/Images/Gallery/20150413/thumb_201504131313047068.jpg', NULL, N'A到Z的距离，走过的故事，偶然发现的一组图，每个字母代表着一种意义，每个字母带着一句话，充满了回忆和思念（小编发现只能上传20张图片，人生总是不完美的，对吧？）', 21, 0, CAST(0x0000A47900D98477 AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'5786e811-5682-4ee1-949a-a47900db22ac', N'韩国短片《闹钟》高清壁纸', N'/Images/Gallery/20150413/thumb_201504131318506846.jpg', NULL, N'闹钟是韩国导演Jang Moo Hyun 2009 SIGGRAPH 参展作品。没有对白，只是一只宅男住在单身公寓，早上被闹钟折腾起床的情节，却充分的反映出了当下都市人生活状态。（分享地址：http://pan.baidu.com/s/1pJHVnxp）', 18, 0, CAST(0x0000A47900DB22AC AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'aa25f8b7-1525-4c31-bc98-a479013c91bf', N'Pexels图片欣赏', N'/Images/Gallery/20150413/thumb_201504131951004903.jpg', NULL, N'Pexels:免费高品质图片下载网是一提供海量共享图片素材的网站，每周都会定量更新，所有的图片都会显示详细的信息，例如拍摄的相机型号、光圈、焦距、ISO、图片大分辨率等，高清大图质量很不错的。', 15, 0, CAST(0x0000A479013C91BE AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', N'童年记忆', N'/Images/Gallery/20150413/thumb_201504132012465803.jpg', NULL, N'无以伦比，美轮美奂的童年珍贵记忆', 13, 0, CAST(0x0000A479014D04CB AS DateTime))
INSERT [dbo].[Atlas] ([AtlasId], [AtlasName], [ThumbPath], [AtlasPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'a1492906-bed3-488d-aeb9-a47901512aa8', N'光影记录', N'/Images/Gallery/20150413/thumb_201504132027568344.jpg', NULL, N'光影记录,光与影的完美结合 ', 19, 0, CAST(0x0000A47901512AA6 AS DateTime))
SET IDENTITY_INSERT [dbo].[Book] ON 

INSERT [dbo].[Book] ([BookId], [BookName], [Remark], [ThumbPath], [Category], [Author], [Press], [PageNum], [Grade], [EvaluateTimes], [Hits], [HasResource], [ResourcePath], [BookDescribing], [AuthorDepict], [CommentNum], [CreateTime], [PublishedTime], [CoverPath], [Already], [Wish], [Reading]) VALUES (1, N'暗时间', N'如果你有一台计算机，你装了一个系统之后就整天把它搁置在那里，你觉得这台计算机被实际使用了吗？没有。', N'/Images/Books/20150413/201504130111572146.jpg', N'专业技术', N'刘未鹏 ', N'电子工业出版社', 251, CAST(0.0 AS Decimal(18, 1)), 0, 5, 1, N'http://pan.baidu.com/s/1jG8BVeA', N'<div class="intro">
	<p>
		2003年，刘未鹏在杂志上发表了自己的第一篇文章，并开始写博客。最初的博客较短，也较琐碎，并夹杂着一些翻译的文章。后来渐渐开始有了一些自己的心得和看法。总体上在这8年里，作者平均每个月写1篇博客或更少，但从未停止。
	</p>
	<p>
		刘未鹏说——
	</p>
	<p>
		写博客这件事情给我最大的体会就是，一件事情如果你能够坚持做8年，那么不管效率和频率多低，最终总能取得一些很可观的收益。而另一个体会就是，一件事情只要你坚持得足够久，“坚持”就会慢慢变成“习惯”。原本需要费力去驱动的事情便成了家常便饭，云淡风轻。
	</p>
	<p>
		这本书便是从刘未鹏8年的博客文章中精选出来的，主要关于心智模式、学习方法和时间利用，《暗时间》的书名便来自于此。
	</p>
</div>', N'<div class="intro">
	<p>
		刘未鹏：
	</p>
	<p>
		南京大学计算机系硕士毕业
	</p>
	<p>
		现就职于微软亚洲研究院创新工程中心
	</p>
	<p>
		兴趣爱好：计算机科学，人工智能，认知科学
	</p>
	<p>
		博客名 Mind Hacks 的含义：
	</p>
	<p>
		- Mind Hacks 是一本书
	</p>
	<p>
		- Mind Hacks 是一系列思维工具
	</p>
	<p>
		- Mind Hacks 有一个漫长的前生—一个有着近6年历史的技术博客
	</p>
	<p>
		- 在CSDN上有超过120万的访问量
	</p>
</div>', 0, CAST(0x0000A4790013C33F AS DateTime), N'2011-7', NULL, 0, 0, 0)
INSERT [dbo].[Book] ([BookId], [BookName], [Remark], [ThumbPath], [Category], [Author], [Press], [PageNum], [Grade], [EvaluateTimes], [Hits], [HasResource], [ResourcePath], [BookDescribing], [AuthorDepict], [CommentNum], [CreateTime], [PublishedTime], [CoverPath], [Already], [Wish], [Reading]) VALUES (2, N'影响力', N'影响力，职业五力模型第三层，包括人际沟通、说服演讲、品牌营销等。改变别人观念，影响别人行动的能力。影响力强的人喜欢和人交流，善于鼓舞，情绪起伏变化。', N'/Images/Books/20150413/201504130116479672.jpg', N'心理科普', N'[美] 罗伯特·B·西奥迪尼', N'万卷出版公司', 286, CAST(0.0 AS Decimal(18, 1)), 0, 5, 0, NULL, N'<div class="para">
	编辑手记
</div>
<div class="para">
	关于《影响力》
</div>
<div class="para">
	序言
</div>
<div class="para">
	第1章影响力的武器
</div>
<div class="para">
	为什么无人问津的东西，价格乘以2以后，反而被一抢而空？<br />
为什么房地产商在售楼时，会先带顾客去看没人会买的破房子？
</div>
<div class="para">
	为什么汽车经销商在顾客掏钱买车之后才会建议顾客购买各种配件？
</div>
<div class="para">
	第2章互惠
</div>
<div class="para">
	为什么精明的政客会让连普通人都能看出来的愚蠢的“水门事件”发生？
</div>
<div class="para">
	为什么我们明明不喜欢某个人，却对他提出的要求无法拒绝？
</div>
<div class="para">
	为什么超市总喜欢提供“免费试用”？
</div>
<div class="para">
	第3章承诺和一致
</div>
<div class="para">
	为什么像宝洁和通用食品这样的大公司，经常发起有奖征文比赛，参赛者无需购买该公司任何产品，却有机会获得大奖？
</div>
<div class="para">
	为什么一些二手车经销商在收购旧车时，会故意高估旧车的价格？
</div>
<div class="para">
	第4章社会认同
</div>
<div class="para">
	在遇到紧急情况时，什么才是最有效的求救方式？
</div>
<div class="para">
	为什么当自杀事件广为报道时，报道所覆盖的地区自杀事件反而增多了？
</div>
<div class="para">
	为什么圭亚那琼斯城的910名教徒会集体自杀？
</div>
<div class="para">
	第5章喜好
</div>
<div class="para">
	为什么特百惠公司的家庭聚会能使每天的销售额超过250万美元？
</div>
<div class="para">
	为什么在审讯嫌疑犯的过程中“好警察”、“坏警察”搭档的方法巧妙地运用了喜好原理？
</div>
<div class="para">
	为什么狂怒的球迷会在比赛输掉以后杀死运动员和裁判员？
</div>
<div class="para">
	第6章权威
</div>
<div class="para">
	为什么受过正规培训的护理人员会毫不犹豫地执行一个来自医生的明明漏洞百出的指示？
</div>
<div class="para">
	为什么行骗高手们总是以换装作为一种行骗手段？
</div>
<div class="para">
	第7章稀缺
</div>
<div class="para">
	为什么面值一元的错版纸币，其价值远远超过了面值的几百倍？
</div>
<div class="para">
	为什么在拍卖场里，人们会不由自主地不停举牌？
</div>
<div class="para">
	青少年反叛的根源在哪里？
</div>
<div class="para">
	尾声即时的影响力
</div>', N'<a target="_blank" href="http://baike.baidu.com/view/6202077.htm">罗伯特·西奥迪尼</a>(Robert B．Cialdirli)全球知名的说服术与影响力研究权威。他分别于<a target="_blank" href="http://baike.baidu.com/view/1035140.htm">北卡罗来纳大学</a>、哥伦比亚大学取得<a target="_blank" href="http://baike.baidu.com/view/22607.htm">博士</a>与博士学位，投入说服与顺从行为研究逾3年。如今是亚利桑那州立<a target="_blank" href="http://baike.baidu.com/view/2782287.htm">大学心理</a>学系教授。', 0, CAST(0x0000A479001517F8 AS DateTime), N'2010-9-20', NULL, 0, 0, 0)
INSERT [dbo].[Book] ([BookId], [BookName], [Remark], [ThumbPath], [Category], [Author], [Press], [PageNum], [Grade], [EvaluateTimes], [Hits], [HasResource], [ResourcePath], [BookDescribing], [AuthorDepict], [CommentNum], [CreateTime], [PublishedTime], [CoverPath], [Already], [Wish], [Reading]) VALUES (3, N'心理学与生活', N'《心理学与生活》是美国斯坦福大学多年来使用的教材，也是在美国许多大学里推广使用的经典教材，还是被许多国家大学的“普通心理学”课程选用的教材。', N'/Images/Books/20150413/201504130121300029.jpg', N'心理科普', N'[美] 理查德·格里格', N'人民邮电出版社', 621, CAST(0.0 AS Decimal(18, 1)), 0, 5, 0, NULL, N'序言<br />
第一章 生活中的心理学<br />
第二章 心理学的研究方法<br />
第三章 行为的生物学基础<br />
第四章 感觉<br />
第五章 知觉<br />
第六章 心理，意识和其他状态<br />
第七章 学习与行为分析<br />
第八章 记忆<br />
第九章 认知过程<br />
第十章 智力与智力测验<br />
第十一章 人的毕生发展<br />
第十二章 动机<br />
第十三章 情绪、压力和健康<br />
第十四章 理解人类人格<br />
第十五章 心理障碍<br />
第十六章 心理治疗<br />
第十七章 社会过程与关系<br />
第十八章 社会心理学，社会和文化', N'<div class="intro">
	<p>
		理查德·格里格（Richard J. Gerrig）是美国纽约州立大学的心理学教授。获Lex 
Hixon社会科学领域杰出教师奖。在认知心理学研究领域有专长，是美国心理学会实验心理学分会的会员。从《心理学与生活》这部经典教科书第14版修订时
开始，格里格成为该书的合著者。
	</p>
	<p>
		菲利普·津巴多（Philip G. 
Zimbardo）是美国斯坦福大学的心理学教授，当代著名心理学家，美国心理学会主席。40多年来，由于他在心理学研究和教学领域的杰出贡献，美国心理
学会特向津巴多频发了Hilgard普通心理学终生成就奖。由他开创的《心理学与生活》这部经典教科书哺育了一代又一代心理学工作者。津巴多主动让贤，推
举格里格为《心理学与生活》第16版的第一作者。
	</p>
</div>
	</div>', 0, CAST(0x0000A4790016627B AS DateTime), N'2003-10', NULL, 0, 0, 0)
INSERT [dbo].[Book] ([BookId], [BookName], [Remark], [ThumbPath], [Category], [Author], [Press], [PageNum], [Grade], [EvaluateTimes], [Hits], [HasResource], [ResourcePath], [BookDescribing], [AuthorDepict], [CommentNum], [CreateTime], [PublishedTime], [CoverPath], [Already], [Wish], [Reading]) VALUES (4, N'怪诞心理学', N'其实人类的行为并不像我们想象的那么难以预测。', N'/Images/Books/20150413/201504130125276257.jpg', N'心理科普', N' [英] 理查德·怀斯曼', N' 天津教育出版社', 268, CAST(0.0 AS Decimal(18, 1)), 0, 23, 0, NULL, N'<h2>
	<span class="">目录</span> &nbsp;·&nbsp;·&nbsp;·&nbsp;·&nbsp;·&nbsp;·
</h2>
神奇的Q测试<br />
序<br />
第1章　你的生日到底隐含着怎样的秘密——时间心理学<br />
第2章　相信别人，不过别忘了切牌——撒谎与欺骗心理学<br />
第3章　一切皆有可能——灵异心理学<br />
第4童　下定决心——决策心理学<br />
第5章　以科学的方式搜寻全球最爆笑的笑话——幽默心理学<br />
第6章　是罪人还是圣人——自私心理学<br />
结束语<br />
化解遍布全球的“宴会枯燥症”<br />
大型秘密实验<br />
致谢<br />
附注', N'<div class="para">
	<a target="_blank" href="http://baike.baidu.com/view/2358411.htm">理查德·怀斯曼</a>（Richard Wiseman）
</div>
<div class="para">
	英国著名的大众心理学教授、超级畅销书作家，其代表作为《怪诞心理学》。怀斯曼教授致力于以科学方法研究人们日常生
活中看似无法用理性理解的行为。在伦敦大学攻读心理学学位之前，怀斯曼曾是一名职业魔术师，后获爱丁堡大学心理学博士学位。怀斯曼教授在直觉、欺骗、运
气、幽默和超自然等领域的研究享誉国际，经常与各界名人合作，在BBC等著名媒体上进行以成千上万人为对象的大规模实验。
</div>
<div class="para">
	怀斯曼教授是英国各大报刊杂志最常引述的心理学家。许多世界级顶尖科学期刊报导过怀斯曼的研究；更多国际媒体如《时代杂志》、《每日电讯报》及《卫报》对怀斯曼教授都有专题介绍，怀斯曼教授接受过数百个广播与电视节目专访。<sup>[1]</sup><a name="ref_[1]_11093798"></a>&nbsp;
</div>
<div class="para">
	理查德·怀斯曼教授拥有“英国大众心理学传播第一教授”的头衔，他在包括欺骗、运气、幽默和超自然等不寻常领域的研究享誉国际，他是英国媒体最常引用的心理学家，他的研究在英国超过150个电视节目上播出。他定期出现在<a target="_blank" href="http://baike.baidu.com/view/60739.htm">英国广播公司</a>第四电台做节目，有关他工作的专题报道更是频频出现在英国各报刊杂志上。
</div>', 0, CAST(0x0000A479001778F2 AS DateTime), N'2009-07-01', NULL, 0, 0, 0)
SET IDENTITY_INSERT [dbo].[Book] OFF
SET IDENTITY_INSERT [dbo].[Feedback] ON 

INSERT [dbo].[Feedback] ([FeedbackId], [FeedbackName], [StartTime], [EndTime], [Status], [CreateTime]) VALUES (1, N'2016年10月份心理反馈', CAST(0x0000A69A00000000 AS DateTime), CAST(0x0000A6AD00000000 AS DateTime), -1, CAST(0x0000A699018739B9 AS DateTime))
SET IDENTITY_INSERT [dbo].[Feedback] OFF
SET IDENTITY_INSERT [dbo].[LoginLog] ON 

INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (1, 1, N'雪影蓝枫', N'120.236.154.208', N'', CAST(0x0000A478014F8458 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (2, 1, N'雪影蓝枫', N'::1', N'', CAST(0x0000A478015504D2 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'后台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (3, 1, N'雪影蓝枫', N'120.236.154.208', N'', CAST(0x0000A4790003CBEB AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (4, 1, N'雪影蓝枫', N'120.236.154.208', N'', CAST(0x0000A47900998354 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'后台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (5, 1, N'雪影蓝枫', N'120.236.154.208', N'www.quisque.cn', CAST(0x0000A47B00F31E38 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'后台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (6, 1, N'雪影蓝枫', N'120.236.154.208', N'www.quisque.cn', CAST(0x0000A47C00BD22B3 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'后台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (7, 1, N'雪影蓝枫', N'120.236.154.208', N'www.quisque.cn', CAST(0x0000A48000D02257 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'后台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (8, 1, N'雪影蓝枫', N'120.236.154.208', N'www.quisque.cn', CAST(0x0000A48700B39D45 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0', N'后台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (9, 1, N'雪影蓝枫', N'::1', N'localhost', CAST(0x0000A6260013919F AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (10, 1, N'雪影蓝枫', N'::1', N'localhost', CAST(0x0000A69901841D6C AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:49.0) Gecko/20100101 Firefox/49.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (11, 1, N'雪影蓝枫', N'::1', N'localhost', CAST(0x0000A6BC011F9370 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:49.0) Gecko/20100101 Firefox/49.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (12, 1, N'雪影蓝枫', N'::1', N'localhost', CAST(0x0000A7F50131BD63 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (13, 1, N'Admin', N'::1', N'localhost', CAST(0x0000A7F5013A2AD6 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0', N'前台登录')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (14, 1, N'Admin', N'::1', N'localhost', CAST(0x0000A7F5013C8EBA AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0', N'后台退出')
INSERT [dbo].[LoginLog] ([LoginLogId], [UserId], [UserName], [IP], [ComputerName], [LoginTime], [Platform], [UserAgent], [Type]) VALUES (15, 1, N'Admin', N'::1', N'localhost', CAST(0x0000A7F5013CE059 AS DateTime), N'WinNT', N'Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0', N'后台登录')
SET IDENTITY_INSERT [dbo].[LoginLog] OFF
SET IDENTITY_INSERT [dbo].[News] ON 

INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (1, N'放飞心灵，结谊今朝', N'求索活动', 0, N'<span>12</span><span>月</span><span>8</span><span>日</span><span>下午，由信息学院、软件学院求索工作室以及食品学院阳光加油站联合举办的心理沙龙活动在东区实验楼三楼架空层获得圆满成功</span><span style="line-height:150%;font-family:宋体;color:#333333;">。</span><span>两个学院各年级的学生代表、求索工作室以及阳光加油站的成员携手参加了本次活动。</span> 
<p>
	<span>&nbsp;&nbsp; &nbsp; &nbsp; &nbsp;</span><span>活动的第一部分是沙龙游戏。首先进行的是</span><span>“</span><span>新手对决</span><span>”</span><span>，
即随机把现场人员分为两队进行对决，对决人员依次说出自己希望的称呼，先说出对方称呼的胜者可将对面成员“俘虏”至自己组，直至其中一方少于三人。在这环
节中，大家通过调换位置的过程相互熟络，打破了彼此间的隔膜。这个游戏的目的不仅在于让组员之间有相互的认识、方便后面环节的进行，更在于告诉大家，快速
记住人名是一项人际交往中必不可少的技能。</span> 
</p>
<p style="text-indent:21.0pt;">
	<span>接下来进行的两个游戏分别是“信任之
旅”和“无敌风火轮”。同学们都被这两个有趣的游戏吸引了，虽然挺有难度，但是都在与组员的商量和协调下完成了游戏。有的因为默契和合作十分顺利地获得成
功，有的在历经困难后坚持不懈地完成任务。在这一环节中，大家的脸上都洋溢着游戏带来的欢乐。而这两个韵味十足的游戏主要是为了培养大家团结合作、共对难
关的团队精神，并且让大家在快乐的游戏中深刻地了解到个人的力量在集体中也是不可忽视的，有利于大家更好地融入集体。</span> 
</p>
<p style="text-indent:21.0pt;">
	<span>&nbsp;三个欢乐的游戏过后，就是活动的第二部分，交流与评价。活动参与者或者分享了自己收获的快乐、或者交流自己领悟到的一些道理、或者客观地表达了自己对活动的评价和看法，让本次活动得到了很好的升华。</span> 
</p>
<p style="text-indent:21.0pt;">
	<span>最后，本次心理沙龙活动在合影之后落下帷幕。<span>此次活动的意义不仅在于拉近两个学院之间的距离、为两院学生搭建一个增进友谊的桥梁，更在于让同学们在快乐中收获一些有用的知识和技能。</span></span><span><span></span></span><span style="font-family:宋体;">（图：李裕霖</span><span>&nbsp;&nbsp;&nbsp; </span><span style="font-family:宋体;">文：黎颖、张维国）</span>
</p>
<p style="text-indent:21.0pt;" align="center">
	<span style="font-family:宋体;"><img src="/Attached/News/image/20150413/20150413001957_2282.jpg" alt="" /><br />
</span> 
</p>', 9, 0, NULL, CAST(0x0000A29000E8A2B0 AS DateTime), N'/Images/News/20150412/201504122035015922.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (2, N'DV剧动员大会暨征文表彰大会 ', N'求索活动', 0, N'<p style="text-indent:21pt;" align="left">
	<span style="color:#555555;">12</span><span>月</span><span style="color:#555555;">13</span><span>日中午，由信息学院、软件学院求索工作室举办的</span><span style="color:#555555;">DV</span><span>剧动员大会暨征文表彰大会在院楼</span><span style="color:#555555;">500</span><span>顺利开展。求索工作室室长廖桂发，副室长马学伟、林文盛，上一届</span><span style="color:#555555;">DV</span><span>剧大赛获奖作品主演以及</span><span style="color:#555555;">2011</span><span>、</span><span style="color:#555555;">2012</span><span>、</span><span style="color:#555555;">2013</span><span>级各班心委和</span><span style="color:#555555;">2013</span><span>级班委代表参加了会议。</span><span style="color:#555555;"></span>
</p>
<p style="text-indent:21pt;" align="left">
	<span style="line-height:150%;font-family:宋体;color:#555555;">首先进行的是<span>DV</span>剧动员环节。在主持人胡心怡精彩的介绍之后，大家一起观看了上一届<span>DV</span>剧大赛获奖作品《路一直都在》以及《这一次我想选咖啡》，精彩的画质和演员们纯熟的演技赢得了观众的阵阵掌声。接着，《路一直都在》的三位主演依次上台发言，与大家分享了拍摄期间的各种心得，并动员大家积极参与到<span>DV</span>剧的拍摄活动中。接下来，本次<span>DV</span>剧主讲人庄郁菲就本次大赛的主题、赛制以及提交方式等内容作了详尽的说明。<span></span></span>
</p>
<p style="text-indent:21pt;" align="left">
	<span style="line-height:150%;font-family:宋体;color:#555555;">最后进行的是心理征文颁奖环节。求索工作室室长廖桂发，副室长马学伟及林文盛依次给获奖作者颁奖并合影留念。在观众们热烈的掌声中，此次<span>DV</span>剧动员大会暨征文表彰大会圆满的落下了帷幕。正所谓生活不缺少美，而是缺少发现美的眼睛，也相信大家能通过此次活动用镜头发现身边更多的美。</span><span style="font-size:12pt;line-height:24px;font-family:宋体;color:#555555;">（图：钟卓伦</span><span style="font-size:12pt;line-height:24px;font-family:Verdana, sans-serif;color:#555555;">&nbsp;</span><span style="font-size:12pt;line-height:24px;font-family:宋体;color:#555555;">文：黎颖）</span>
</p>
<p style="text-indent:21pt;" align="center">
	<span style="font-size:12pt;line-height:24px;font-family:宋体;color:#555555;"><img src="/Attached/News/image/20150413/20150413002151_0915.jpg" alt="" /></span>
</p>
<p style="text-indent:21pt;" align="center">
	<span style="font-size:12pt;line-height:24px;font-family:宋体;color:#555555;"><b><span style="line-height:28px;color:#555555;font-family:宋体;font-size:12pt;">征文比赛的获奖名单如下：</span></b> 
	<div align="center">
		<table style="border-collapse:collapse;border:none;" border="1" cellpadding="0" cellspacing="0">
			<tbody>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>奖项</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.65pt;" align="left">
							<span>班级</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:16.6pt;" align="left">
							<span>姓名</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>一等奖</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.65pt;" align="left">
							<span style="color:#555555;">2013</span><span>级软件工程</span><span style="color:#555555;">4</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:13.95pt;" align="left">
							<span>卓新苗</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2012</span><span>级测绘工程</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>吴生伟</span><span style="color:#555555;"> </span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>二等奖</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.65pt;" align="left">
							<span style="color:#555555;">2012</span><span>级测绘工程</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:13.95pt;" align="left">
							<span>魏海婷</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2011</span><span>级信息管理与信息系统</span><span style="color:#555555;">4</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>郑伟璇</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2013</span><span>级信息管理与信息系统</span><span style="color:#555555;">4</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>庄郁菲</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2013</span><span>级工业工程</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>潘荣沃</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>三等奖</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.65pt;" align="left">
							<span style="color:#555555;">2012</span><span>级地理信息系统</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:13.95pt;" align="left">
							<span>冯珊珊</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2012</span><span>级计算机科学与技术</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>陈思博</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2011</span><span>级工业工程</span><span style="color:#555555;">4</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>杨志鹏</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2013</span><span>级信息管理与信息系统</span><span style="color:#555555;">2</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>于欣桐</span><span></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2013</span><span>级工业工程</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span>原文刚</span><span>&nbsp;&nbsp;</span><span style="color:#555555;"></span>
						</p>
					</td>
				</tr>
				<tr>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="67">
						<p align="left">
							<span>&nbsp;</span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="239">
						<p style="margin-left:9.15pt;" align="left">
							<span style="color:#555555;">2013</span><span>级网络工程</span><span style="color:#555555;">1</span><span>班</span><span></span>
						</p>
					</td>
					<td style="border:solid windowtext 1.0pt;" valign="top" width="85">
						<p style="margin-left:12.9pt;" align="left">
							<span style="font-family:宋体;color:#555555;">陈曼青</span>
						</p>
					</td>
				</tr>
			</tbody>
		</table>
	</div>
<br />
</span>
</p>', 14, 0, NULL, CAST(0x0000A2970174B610 AS DateTime), N'/Images/News/20150413/201504130022093635.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (3, N'没那么简单—我院举办大学生性健康专题讲座 ', N'求索活动', 0, N'<p style="text-indent:23.5pt;" align="left">
	<span><span style="color:black;font-family:宋体;line-height:24px;">为了进一步普及大学生性生理和性心理健康知识，</span><span style="color:black;line-height:24px;"><span style="color:#555555;font-family:''Times New Roman'';">&nbsp;3</span></span><span style="color:black;font-family:宋体;line-height:24px;">月</span><span style="color:black;line-height:24px;"><span style="color:#555555;font-family:''Times New Roman'';">7</span></span><span style="color:black;font-family:宋体;line-height:24px;">日</span><span style="color:black;font-family:宋体;line-height:24px;">晚，在</span></span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">女生节来临之际，我院心理辅导站求索工作室邀请了校心理健康辅导中心蔡瑾老师在院楼</span><span style="color:black;line-height:24px;"><span style="color:#555555;font-family:''Times New Roman'';"><span>500</span></span></span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">举办了一场主题为“没那么简单”的大学生性健康专题讲座。</span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;"></span>
</p>
<p style="text-indent:24pt;font-size:12px;" align="left">
	<span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">蔡
老师以其丰富的经验和医学知识，用诙谐幽默的语言和贴近生活的实例，从性生理健康、性心理健康、大学生性行为以及各种避孕措施等方面做了详细的性知识普
及。此次讲座还涉及了生殖健康知识、青春期生理特点、女性自我防护及心理健康知识，详细讲解了女性生理发展的自我保护和心理的自我调节过程，这不仅增加了
同学们对性健康问题的重视度，也提升了大学生的自我保护意识，同时也</span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">引导同学们要树立健康的性意识和科学的性知识。</span>
</p>
<p style="text-indent:24pt;font-size:12px;" align="left">
	<span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;"><img src="/Attached/News/image/20150413/20150413002537_7327.jpg" alt="" /></span>
</p>
<p style="text-indent:24pt;font-size:12px;" align="left">
	<span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;"><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">本次性健康教育讲座为在校大学生指点迷津，宣传和普及了性生理和性心理健康知识，为广大学子性健康教育发展打下了坚实的基础，为其更好地成长、成才保驾护航。</span></span>
</p>
<p style="text-indent:24pt;font-size:12px;" align="left">
	<span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;"><img src="/Attached/News/image/20150413/20150413002600_1602.jpg" alt="" /></span>
</p>
<p style="text-indent:24pt;font-size:12px;" align="left">
	<span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">
	<p style="text-indent:24pt;font-size:12px;" align="left">
		<span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">（文</span><span style="color:black;font-size:12pt;line-height:24px;"><span style="color:#555555;font-size:12px;font-family:''Times New Roman'';">/</span></span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">吴媛媛</span><span style="color:black;font-size:12pt;line-height:24px;"><span style="color:#555555;font-size:12px;"><span style="font-family:''Times New Roman'';">&nbsp;&nbsp;</span></span></span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">图</span><span style="color:black;font-size:12pt;line-height:24px;"><span style="color:#555555;font-size:12px;font-family:''Times New Roman'';">/</span></span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">吴佳宜</span><span style="color:black;font-size:12pt;line-height:24px;"><span style="color:#555555;font-size:12px;font-family:''Times New Roman'';">&nbsp;</span></span><span style="color:black;font-size:12pt;font-family:宋体;line-height:24px;">信息（软件）学院求索工作室）</span>
	</p>
</span>
</p>', 8, 0, NULL, CAST(0x0000A2EB0183D140 AS DateTime), N'/Images/News/20150413/201504130026165591.JPG')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (4, N'求索工作室举办第六届DV剧大赛', N'求索活动', 0, N'<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-indent:24pt;">
	<span style="font-family:宋体;font-size:12pt;line-height:24px;">信息学院、软件学院求索工作室举办的<span style="font-family:Verdana, 宋体;font-size:12px;">DV</span>剧决赛于<span style="font-family:Verdana, 宋体;font-size:12px;">4</span>月<span style="font-family:Verdana, 宋体;font-size:12px;">25</span>日晚在院楼<span style="font-family:Verdana, 宋体;font-size:12px;">500</span>顺利举行。校心理健康辅导中心金艺花老师、工作室指导老师毛丹鹃老师以及<span style="font-family:Verdana, 宋体;font-size:12px;">13</span>级辅导员陈思老师、林晓珊老师应邀出席了本次决赛。<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span> 
</p>
<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-indent:21pt;">
	<span style="font-family:宋体;font-size:12pt;line-height:24px;">本次<span style="font-family:Verdana, 宋体;font-size:12px;">DV</span>剧大赛面向信息学院、软件学院全体学生，以班级为单位征集<span style="font-family:Verdana, 宋体;font-size:12px;">DV</span>作品，并提供了“</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">在路上</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">”、“</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">回到最开始的地方</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">”两大主题给大家选择。经过<span style="font-family:Verdana, 宋体;font-size:12px;">3</span>个多月的筹备、开拍与后期制作之后，<span style="font-family:Verdana, 宋体;font-size:12px;">8</span>部视角独特、风格迥异的<span style="font-family:Verdana, 宋体;font-size:12px;">DV</span>作品成功入围决赛。<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span> 
</p>
<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-indent:24pt;" align="left">
	<span style="font-family:宋体;font-size:12pt;line-height:24px;">决赛现场首先依次播放了进入决赛的<span style="font-family:Verdana, 宋体;font-size:12px;">8</span>部优秀作品。各班的作品画面精致、剧情独特，不仅贴近大学生活，而且充满了正能量，在场的观众们产生强烈的心灵共鸣。这些内涵丰富、充满青春朝气的<span style="font-family:Verdana, 宋体;font-size:12px;">DV</span>剧体现了各参赛班级三个月以来的充分准备和精心制作。作品播放完毕后，金艺花老师进行了精彩的点评。金老师谈到，“大学毕业后，我们可以回到校园，而大学生活却再也回不去了，所以我们要做一个先知先觉的人。”金老师的发言为大赛升华，而穿插在</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">DV</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">剧放映期间的</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">歌唱表演、简答环节和抽奖环节则为大赛增色。<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span> 
</p>
<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-indent:24pt;">
	<span style="font-family:宋体;font-size:12pt;line-height:24px;">大赛决出一等奖<span style="font-family:Verdana, 宋体;font-size:12px;">1</span>名、二等奖<span style="font-family:Verdana, 宋体;font-size:12px;">2</span>名、三等奖<span style="font-family:Verdana, 宋体;font-size:12px;">3</span>名、优秀奖<span style="font-family:Verdana, 宋体;font-size:12px;">2</span>名，其中<span style="font-family:Verdana, 宋体;font-size:12px;">13</span>级软件工程<span style="font-family:Verdana, 宋体;font-size:12px;">4</span>班拔得了头筹。颁奖嘉宾为获奖班级颁发了证书和礼品，给大赛</span><span style="font-family:宋体;font-size:12pt;line-height:24px;">画下了圆满的句号。</span> 
</p>
<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-indent:24pt;">
	<span style="font-family:宋体;font-size:12pt;line-height:24px;"><img src="/Attached/News/image/20150413/20150413002732_2071.jpg" alt="" /></span>
</p>
<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-indent:24pt;">
	<span style="font-family:宋体;font-size:12pt;line-height:24px;">
	<div style="text-align:center;">
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-align:start;">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">本次大赛获奖名单如下：<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span>
		</p>
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-align:start;">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">&nbsp;<b> 奖项<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp; &nbsp; &nbsp;</span></span>班级</b><span style="font-family:Verdana, 宋体;font-size:12px;"></span></span>
		</p>
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-align:start;">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">一等奖：<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;</span>13</span>级软工<span style="font-family:Verdana, 宋体;font-size:12px;">4</span>班<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span>
		</p>
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-align:start;">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">二等奖：<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;</span>12</span>级信管<span style="font-family:Verdana, 宋体;font-size:12px;">4</span>班，<span style="font-family:Verdana, 宋体;font-size:12px;">13</span>级软工<span style="font-family:Verdana, 宋体;font-size:12px;">2</span>班<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span>
		</p>
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-align:start;">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">三等奖：<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;</span>12</span>软件<span style="font-family:Verdana, 宋体;font-size:12px;">R8</span>班，<span style="font-family:Verdana, 宋体;font-size:12px;">12</span>地信<span style="font-family:Verdana, 宋体;font-size:12px;">1</span>班，<span style="font-family:Verdana, 宋体;font-size:12px;">13</span>信管<span style="font-family:Verdana, 宋体;font-size:12px;">3</span>班<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span>
		</p>
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;text-align:start;">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">优秀奖：<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;</span>13</span>计机<span style="font-family:Verdana, 宋体;font-size:12px;">4</span>班，<span style="font-family:Verdana, 宋体;font-size:12px;">13</span>计机<span style="font-family:Verdana, 宋体;font-size:12px;">3</span>班<span style="font-family:Verdana, 宋体;font-size:12px;"></span></span>
		</p>
		<p style="font-family:Verdana, 宋体;font-size:12px;color:#555555;" align="center">
			<span style="font-family:宋体;font-size:12pt;line-height:24px;">（文：吴媛媛<span style="font-family:Verdana, 宋体;font-size:12px;">/</span>李华坤<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;</span></span>图：林安琪<span style="font-family:Verdana, 宋体;font-size:12px;"><span>&nbsp;&nbsp;</span></span>求索工作室）</span>
		</p>
	</div>
<br />
</span> 
</p>', 37, 0, NULL, CAST(0x0000A31B012A4760 AS DateTime), N'/Images/News/20150413/201504130027385530.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (5, N'感恩之花 开满枝头 ', N'求索活动', 0, N'<span style="line-height:28px;font-family:宋体;"></span><span>11</span>月<span>23</span>日<span style="line-height:28px;font-family:宋体;">晚，在满怀期待中，我们迎来了由信息学院软件学院、动物科学学院、水利与土木工程学院和园艺学院联合举办的演讲比赛总决赛。本次决赛的主题为“感恩”，共有十名在各学院的海选以及决赛中脱颖而出的选手参加了本次的四院总决赛。</span> 
<p>
	<span style="font-family:宋体;">&nbsp;&nbsp; &nbsp;</span><span style="font-family:宋体;">在动感十足的街舞表演作为开场环节后，<span>10</span>位参赛选手依次开始自己的第一轮命题演讲。各位选手在演讲中以不同的角度、激越的情怀、真诚的情感表达了他们对父母、老师、学校、以及社会的感恩之心，引起台上台下所有人的共鸣。<span></span></span>
</p>
<p>
	<span style="font-family:宋体;">&nbsp; &nbsp;&nbsp;</span><span style="font-family:宋体;">在第一轮激烈的主题演讲过后，现场还特意安排了激奋人心的微博墙抽奖活动
环节，随后是紧张激烈的第二轮演讲比赛——即兴演讲。此环节充分考验选手们的临场应变能力和语言表达能力。选手们有的幽默诙谐，有的沉熟稳重，有的激情昂
扬，每个人都通过比赛展现了自己高超的口语表达能力和各具特色的人格魅力。一段段文辞优美的叙述，无不引起观众的强烈共鸣，掌声不断。<span></span></span>
</p>
<p>
	<span style="font-family:宋体;">&nbsp; &nbsp;&nbsp;</span><span style="font-family:宋体;">经过两轮激烈的角逐，一等奖由动物科学学院的鄂纲笑同学获得。信息学院软件学院的选手也取得了不错的成绩，其中李淑君和谭春霞选手分别斩获二等奖和三等奖。活动由温馨感人的手语表演作为收尾，让比赛在欢笑和感动中画上完美的句号。<span></span></span>
</p>
<p>
	<span style="line-height:28px;font-family:宋体;"><span style="line-height:28px;">&nbsp; &nbsp;&nbsp;</span><span style="line-height:28px;">此次比赛不仅为同学们搭建了一个抒发感恩之情、展现当代大学生风采的平台，同时也拉近了四个学院之间的距离。活动举办的意义更在于希望能够看到感恩之花开满枝头，让阳光洒进学生们的心灵。</span>(</span><span style="line-height:28px;font-family:宋体;">图片源自</span><span style="line-height:28px;font-family:宋体;">学生会新闻部</span><span style="line-height:28px;">)</span>
</p>
<p>
	<span style="line-height:28px;"><img src="/Attached/News/image/20150413/20150413002946_5540.jpg" alt="" /><br />
</span>
</p>', 7, 0, NULL, CAST(0x0000A28001728390 AS DateTime), N'/Images/News/20150413/201504130029508832.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (6, N'求索心理电影播放活动', N'求索活动', 0, N'<span style="font-family:宋体;">11</span><span style="font-family:宋体;">月<span>1</span>日</span><span style="font-family:宋体;">晚，信息学院、软件学院求索工作室第一次心理电影放映活动在第四教学楼<span>104</span>室开展。此次电影播放活动面向学院全体学生，意义在于通过此次电影播放使同学们从忙碌学习中得到适当放松。<span></span></span> 
<p class="MsoNormal" style="text-indent:21.0pt;">
	<span style="font-family:宋体;">本次播放的电影为励志片《逆光飞翔》，讲述的是
两个平凡而坚强的人追逐梦想的故事，内容虽然平淡，但是带给我们的却是对生活的深刻感受。有了梦，就跟从自己的心，向着自己的方向飞，飞向远方。此次电影
播放活动正值新生开学两个月之际，同学们都在努力追逐自己的梦想，电影所表达的正契合同学们的心境。观影之后，主持人采海杰邀请了现场几位观众谈谈自己的
感受。让人惊喜的是，很多观众都说出了本次活动的主题“有梦就勇敢去追”。<span></span></span>
</p>
<p class="MsoNormal" style="text-indent:21.0pt;">
	<span style="font-family:宋体;">活动在主持人总结中圆满结束，作为求索工作室在新学年首个面向学院全体学生的活动，本次活动相信已经在本院学生中留下了深刻的印象，这对于我们日后更加深入地开展学生心理活动有着非凡的意义。</span>
</p>
<p class="MsoNormal" style="text-indent:21.0pt;" align="center">
	<span style="font-family:宋体;"><img src="/Attached/News/image/20150413/20150413003615_7143.jpg" alt="" /></span>
</p>
<p class="MsoNormal" style="text-indent:21.0pt;" align="center">
	<span style="font-family:宋体;"><img src="/Attached/News/image/20150413/20150413003630_4013.jpg" alt="" /></span>
</p>
<p class="MsoNormal" style="text-indent:21.0pt;">
	<span style="font-family:宋体;"><br />
</span>
</p>', 2, 0, NULL, CAST(0x0000A27401617C30 AS DateTime), N'/Images/News/20150413/201504130036483170.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (7, N'越野寻标赛 赛出真自我', N'求索活动', 0, N'<span>10</span><span>月</span><span>27</span><span>日上午</span><span>9</span><span>时</span><span style="line-height:150%;font-family:宋体;">，由</span><span style="line-height:150%;">11</span><span style="line-height:150%;font-family:宋体;">、</span><span style="line-height:150%;">12</span><span style="line-height:150%;font-family:宋体;">、</span><span style="line-height:150%;">13</span><span style="line-height:150%;font-family:宋体;">级心理委员以及信息学院、软件学院求索工作室成员共</span><span style="line-height:150%;">15</span><span style="line-height:150%;font-family:宋体;">人组成的</span><span style="line-height:150%;">3</span><span style="line-height:150%;font-family:宋体;">支徒步寻标队伍集中在华南农业大学五山大草坪开始越野寻标赛</span><span>。本次比赛</span><span style="line-height:150%;font-family:宋体;">将以</span><span style="line-height:150%;">5</span><span style="line-height:150%;font-family:宋体;">人一组的方式按图寻找</span><span style="line-height:150%;">8-9</span><span style="line-height:150%;font-family:宋体;">个标点，最先完成任务者优胜。</span> 
<p>
	<span>&nbsp; &nbsp; &nbsp; &nbsp;</span><span>在随机分组后，队长随机选择含有指定目标的信封，就这样</span><span>3</span><span>支队伍出发了。</span>
</p>
<p>
	<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span><span>经过一轮体力、智力、团体合作能力等一系列综合素质的大比拼后，由工作室副室长林文盛领衔的队伍在上午</span><span style="line-height:150%;">10</span><span>时</span><span style="line-height:150%;">15</span><span>分率先到达了本次越野寻标赛的终点——华南农业大学南门。在奖励与“惩罚”之后，在所有参赛者以及策划活动的外联部副部长张玙瑶、工作室室长廖桂发合影后，本次越野寻标赛宣告结束。</span><span style="line-height:150%;"></span>
</p>
<p>
	<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span><span>本次寻标赛为心委以及工作室成员提供了锻炼身体和意志的好机会，还锻炼了大家的团队合作精神。参赛者的聪明才智、身体素质、应变能力都得到了充分的发挥。它丰富了大家的课余生活，锻炼出其坚韧不拔的意志，促进其身心的发展。</span><span> <br />
</span>
</p>
<p align="center">
	<span><img src="/Attached/News/image/20150413/20150413003752_1374.jpg" alt="" /><br />
</span>
</p>', 3, 0, NULL, CAST(0x0000A274015FD650 AS DateTime), N'/Images/News/20150413/201504130037560154.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (8, N'心委齐聚 接力求索', N'求索活动', 0, N'<span>10</span><span>月</span><span>11</span><span>日</span><span>中午，</span><span>2013-2014</span><span>学年信息学院、软件学院第一次心理委员会议在第三教学楼</span><span>201</span><span>室举行</span><span>,</span><span>工作室指导老师毛丹鹃老师、求索工作室全体人员以及</span><span>13</span><span>、</span><span>12</span><span>、</span><span>11</span><span>级各班心理委员也参加会议。</span> 
<p>
	<span>&nbsp; &nbsp; &nbsp; &nbsp;&nbsp;</span><span>本次会议分为三个阶段。首先由指导老师毛丹鹃老师发表演讲。毛老师从多个角度向我们阐述了当代大学生遇到的心理问题，并由此诠释了心委的工作方向以及心委工作的重要性。毛老师强调心理委员除了要关心同学，还要提高他们的沟通能力，多阅读心理书籍，丰富心理知识。</span>
</p>
<p>
	<span>&nbsp; &nbsp; &nbsp; &nbsp;&nbsp;</span><span>第二个阶段，求索学术部部长罗伟林及其副部长郑立楷就相关工作展开了详细地叙述。部长罗伟林介绍了心委的职责、定位、原则以及工作时应遵守的规定。副部长郑立楷对</span><span style="line-height:28px;font-family:宋体;">主题为“给一年后的自己”的征文活动做了详细的介绍，并强调了征文的形式、内容以及其它的注意事项。随后，工作人员还热情地解答了部分心理委员的疑问。</span>
</p>
<p style="text-align:left;">
	<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span><span>最后，</span><span>2013~2014</span><span>学年第一次心理委员会议在合影留念中圆满结束。希望学院各班级心委接力求索工作室，热心帮助同学，为同学解决心理问题，让大家心里都充满阳光，用爱心铸就同学心灵的港湾！</span>
</p>', 3, 0, NULL, CAST(0x0000A274015F49B0 AS DateTime), N'/Images/News/20150413/201504130039227614.jpg')
INSERT [dbo].[News] ([NewsId], [NewsTitle], [Category], [IsTop], [NewsContent], [ViewTimes], [CommentNum], [NewsTags], [CreateTime], [ThumbPath]) VALUES (9, N'新学年，新气象——求索工作室新学期工作会议', N'热点聚焦', 1, N'<p class="MsoNormal" align="left">
	<span style="font-size:14.0pt;">&nbsp;&nbsp; </span><span style="font-size:12.0pt;font-family:宋体;">&nbsp;</span><span style="font-size:12.0pt;font-family:宋体;">近日，学院二级心理辅导站求索工作室于院楼<span>201</span>举
行了本学期第一次全干会。会议以总结过往，展望未来为主题。工作室指导老师毛老师肯定了上学期工作室开展的各项工作，并对新学期的工作提出几点要求：一
是，改进心理反馈方式，提高心理反馈效率；二是，举办心理知识沙龙，丰富心理健康知识；三是，开展室外心理团体活动，增强心理素质。<span></span></span>
</p>
<p>
	<span style="font-size:12.0pt;font-family:宋体;">另外，在院楼<span>500</span>举
行了本学期第一次全院心理委员会议。会议中，毛老师强调了心理委员的工作职责，明确指出了心委工作的重要性，要求心理委员要用心做到认真观察、严格保密、
及时反馈。学科调整后，数学系的心委也要及时融入新学院，适应新学院的工作安排。最后，工作室工作人员介绍了本学期的活动安排，希望心委能够积极参与，并
详细解答了近期的心理<span>DV</span>剧拍摄相关问题。</span>
</p>
<p align="center">
	<span style="font-size:12.0pt;font-family:宋体;"><img src="/Attached/News/image/20150413/20150413105409_6248.jpg" alt="" /></span>
</p>
<p align="center">
	<br />
<span style="font-size:12.0pt;font-family:宋体;">
	<p class="MsoNormal" style="text-indent:24pt;" align="left">
		<span style="font-size:12.0pt;font-family:宋体;">求索工作室将不断完善自己，积极营造健康向上的氛围。<span></span></span>
	</p>
	<p class="MsoNormal" style="text-indent:24pt;" align="left">
		<span style="font-size:12.0pt;font-family:宋体;color:#555555;">（</span><span style="font-size:9pt;line-height:1.5;font-family:Verdana, sans-serif;color:#555555;">&nbsp;</span><span style="font-size:12pt;font-family:宋体;color:#555555;">文：黄颖 &nbsp;&nbsp;</span><span style="font-size:12pt;font-family:宋体;color:#555555;">图：刘傲飞</span><span style="font-size:9pt;line-height:1.5;font-family:Verdana, sans-serif;color:#555555;">&nbsp;&nbsp;</span><span style="font-size:12pt;font-family:Verdana, sans-serif;color:#555555;">&nbsp;</span><span style="font-size:12pt;font-family:宋体;color:#555555;">）来源于：<span>学工办</span></span>
	</p>
</span>
</p>
<p align="center">
	<span style="font-size:12.0pt;font-family:宋体;"><br />
</span>
</p>', 31, 2, NULL, CAST(0x0000A47900B3DD13 AS DateTime), N'/Images/News/20150413/201504131054516434.jpg')
SET IDENTITY_INSERT [dbo].[News] OFF
SET IDENTITY_INSERT [dbo].[NewsComment] ON 

INSERT [dbo].[NewsComment] ([CommentId], [UpId], [NickName], [Email], [Content], [CreateTime], [NewsId], [IsMember], [UniqueKey]) VALUES (1, 0, N'S9999', N'ylfico08965@chacuo.net', N'做的不错哦，鼓励一下', CAST(0x0000A47B0160700E AS DateTime), 9, 0, N'201504152123111941')
INSERT [dbo].[NewsComment] ([CommentId], [UpId], [NickName], [Email], [Content], [CreateTime], [NewsId], [IsMember], [UniqueKey]) VALUES (2, 0, N'福利', N'23453245@453453453455erww76765.com', N'真的很不错', CAST(0x0000A47B0160B60A AS DateTime), 9, 0, N'201504152124109125')
SET IDENTITY_INSERT [dbo].[NewsComment] OFF
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'15a7ee3f-60b5-4b81-9720-012ab2eb997e', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134414529.jpg', N'/Images/Gallery/20150413/201504131134414529.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECD79 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'6e878d03-53bf-45b3-bff1-04c7e15d2380', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313076522.jpg', N'/Images/Gallery/20150413/201504131313076522.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D6CD AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'848be150-1d4b-45be-92b4-066796c47481', N'5786e811-5682-4ee1-949a-a47900db22ac', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131318506846.jpg', N'/Images/Gallery/20150413/201504131318506846.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900DB68DD AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'b9e3d8d7-c5fd-471b-b925-06fab6cdde72', N'aa25f8b7-1525-4c31-bc98-a479013c91bf', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131951004903.jpg', N'/Images/Gallery/20150413/201504131951004903.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47901471F1D AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'cd9f1f66-c299-4e60-bf0d-086df7dc267a', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313081796.jpg', N'/Images/Gallery/20150413/201504131313081796.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D76B AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'aeb5ffe8-ed88-4b82-bae1-10025902889d', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313113105.jpg', N'/Images/Gallery/20150413/201504131313113105.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DB16 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'43117ee9-e498-4427-b6df-1683a83f84b1', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313122324.jpg', N'/Images/Gallery/20150413/201504131313122324.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DC2B AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'911214ce-72bc-4f5b-bd42-18482bed5798', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233011994.jpg', N'/Images/Gallery/20150413/201504131233011994.jpg', N'性取向测试、如果看到的是女性身体说明你是异性恋，如果你看到两个人在跳舞说明你是同性恋，如果都看到那你就是双性恋', 0, 0, CAST(0x0000A47900CED2BC AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'5b17ac79-4c8d-49c4-9ce0-18b073450f6f', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233033362.jpg', N'/Images/Gallery/20150413/201504131233033362.jpg', N'闭眼的女人：盯着这个女人看，她的眼睛会突然睁开!', 0, 0, CAST(0x0000A47900CED540 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'762dbc2a-ac2c-427b-b251-1d1b2e32b47b', N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132012465803.jpg', N'/Images/Gallery/20150413/201504132012465803.jpg', N'童趣，河边垂钓，幸福的时光', 0, 0, CAST(0x0000A479014D195D AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'8cea0ef9-9a6e-496c-943e-205c3b789afd', N'aa25f8b7-1525-4c31-bc98-a479013c91bf', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131951120903.jpg', N'/Images/Gallery/20150413/201504131951120903.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47901472C74 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'81bf5946-a977-4cd8-a8c9-2f4965d48ca5', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134409099.jpg', N'/Images/Gallery/20150413/201504131134409099.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECCD7 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'a27bda64-262c-4f5a-9a2b-3478286d7d72', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313117685.jpg', N'/Images/Gallery/20150413/201504131313117685.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DBA2 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'd1046149-a1a8-4b6b-8322-38e504fe0b1d', N'a1492906-bed3-488d-aeb9-a47901512aa8', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132027568344.jpg', N'/Images/Gallery/20150413/201504132027568344.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47901514411 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'cc3daa29-ea41-4f61-bbad-3a1fa25e688f', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251324036.jpg', N'/Images/Gallery/20150413/201504131251324036.jpg', N'我也爱你', 0, 0, CAST(0x0000A47900D3E8ED AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'd4a63ac2-44d5-44ba-a7e8-401b7e31ddf9', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313129082.jpg', N'/Images/Gallery/20150413/201504131313129082.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DCFA AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'f2420f16-d18b-47b9-aae6-41f85abdc1c0', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251415562.jpg', N'/Images/Gallery/20150413/201504131251415562.jpg', N'狂欢', 0, 0, CAST(0x0000A47900D3F3A9 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'0f851b8c-8546-4024-a61d-467f22de7d0f', N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132012476731.jpg', N'/Images/Gallery/20150413/201504132012476731.jpg', N'和姐姐妹妹一起跳绳子', 0, 0, CAST(0x0000A479014D1AA5 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'b0c0c7e7-036b-4c32-8758-4d67f448eb50', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134428592.jpg', N'/Images/Gallery/20150413/201504131134428592.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECF20 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'8be123fc-a0ed-4880-9b2b-4ead5db4308b', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251372455.jpg', N'/Images/Gallery/20150413/201504131251372455.jpg', N'蓝胡子，因为觉得太单调所以又改了改。', 0, 0, CAST(0x0000A47900D3EE9E AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'5cd7c682-276f-4991-96f9-4fcdc5d9c183', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251328469.jpg', N'/Images/Gallery/20150413/201504131251328469.jpg', N'即使心里再孤单，世界再荒芜，我-狼孩儿一世', 0, 0, CAST(0x0000A47900D3E975 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'0e48910c-377b-42a8-b915-50a400d28d02', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134388815.jpg', N'/Images/Gallery/20150413/201504131134388815.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECA94 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'ce7842a6-f92a-4bac-85fd-56fc2b937b61', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313059012.jpg', N'/Images/Gallery/20150413/201504131313059012.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D4C0 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'917a7160-1aae-4ae6-8d34-57a8715a8369', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233026868.jpg', N'/Images/Gallery/20150413/201504131233026868.jpg', N'眼睛盯住圆心，用鼠标上下滚动页面，你就会发现圆中有一只扑动翅膀的蝴蝶。看着它，它就很安静，一不看它，它就动起来了。', 0, 0, CAST(0x0000A47900CED47C AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'8f896364-c67f-4543-b872-5af019beed6d', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251332884.jpg', N'/Images/Gallery/20150413/201504131251332884.jpg', N'我也爱你', 0, 0, CAST(0x0000A47900D3E9F8 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'37611511-a29e-4bd8-a6fa-5b3bb03c0afd', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251395200.jpg', N'/Images/Gallery/20150413/201504131251395200.jpg', N'感觉这样静静的，可以睡上一辈子', 0, 0, CAST(0x0000A47900D3F148 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'df9d6898-07c9-4bc4-8e7a-5f34ecc1d0fd', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313054334.jpg', N'/Images/Gallery/20150413/201504131313054334.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D434 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'53546470-1a0e-4e55-818b-6390ad5ec6bd', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313096288.jpg', N'/Images/Gallery/20150413/201504131313096288.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D91E AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'fadeeaa6-a7dd-4720-ad90-667a71a80bdb', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313050887.jpg', N'/Images/Gallery/20150413/201504131313050887.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D3CC AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'4ca8c76f-bbcc-4f1b-ab0b-74d2adb9cd1e', N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132012483733.jpg', N'/Images/Gallery/20150413/201504132012483733.jpg', N'那些年与黄牛小狗在一起的日子', 0, 0, CAST(0x0000A479014D1B77 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'24345c02-a207-4650-a173-75a74552a5ea', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251402095.jpg', N'/Images/Gallery/20150413/201504131251402095.jpg', N'继续作业中', 0, 0, CAST(0x0000A47900D3F215 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'9c288dfe-1e85-4492-b55d-7c282b72f8fb', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134399772.jpg', N'/Images/Gallery/20150413/201504131134399772.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECBBF AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'19c0efa0-6846-405a-93ab-815a2281933e', N'a1492906-bed3-488d-aeb9-a47901512aa8', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132027571899.jpg', N'/Images/Gallery/20150413/201504132027571899.jpg', N'暂无描述...', 0, 0, CAST(0x0000A4790151447C AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'c15eb3db-f53c-4b58-94cb-8922cc8a3a61', N'a1492906-bed3-488d-aeb9-a47901512aa8', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132027578999.jpg', N'/Images/Gallery/20150413/201504132027578999.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47901514551 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'103d44ba-3c15-4331-a4ee-8c431d69e051', N'aa25f8b7-1525-4c31-bc98-a479013c91bf', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131951022872.jpg', N'/Images/Gallery/20150413/201504131951022872.jpg', N'暂无描述...', 0, 0, CAST(0x0000A4790147211B AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'1af62ab8-0e14-446b-89ee-90585b82c63b', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313047068.jpg', N'/Images/Gallery/20150413/201504131313047068.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D359 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'15367a31-ce71-423e-b9cc-91675d3d6827', N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132012471232.jpg', N'/Images/Gallery/20150413/201504132012471232.jpg', N'暂无描述...', 0, 0, CAST(0x0000A479014D1A01 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'e213874f-9984-40c1-a975-91ea973682c5', N'aa25f8b7-1525-4c31-bc98-a479013c91bf', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131951078733.jpg', N'/Images/Gallery/20150413/201504131951078733.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47901472787 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'e809b04e-b288-49e5-b4fe-95e3b73b395b', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233049437.jpg', N'/Images/Gallery/20150413/201504131233049437.jpg', N'这张图是欧普艺术家大内初创作的。前后移动你的头，并让眼睛在画面上转动，你看到了什么？', 0, 0, CAST(0x0000A47900CED722 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'86a13b07-7943-4d73-88f1-97cc157f0285', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134418953.jpg', N'/Images/Gallery/20150413/201504131134418953.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECDFF AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'f504b32a-ad8b-4de0-8523-99e30d507391', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251346019.jpg', N'/Images/Gallery/20150413/201504131251346019.jpg', N'人群中我不过是一尊无人驻足的雕像', 0, 0, CAST(0x0000A47900D3EB88 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'a930b4c8-5687-41b7-bb29-9a6e07d99733', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313065545.jpg', N'/Images/Gallery/20150413/201504131313065545.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D584 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'8234d222-3829-4808-adb4-a72d1b83aaad', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313103398.jpg', N'/Images/Gallery/20150413/201504131313103398.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D9F4 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'dec4feb3-a8f7-4cc1-96c9-a7c3822c7210', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313140908.jpg', N'/Images/Gallery/20150413/201504131313140908.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DE59 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'e2d15c4b-5434-49ed-8357-a8fcacd6677b', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134402448.jpg', N'/Images/Gallery/20150413/201504131134402448.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECC0F AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'8b69454b-d901-4f53-b9e6-ad0539e591c9', N'5786e811-5682-4ee1-949a-a47900db22ac', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131318552746.jpg', N'/Images/Gallery/20150413/201504131318552746.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900DB6E3A AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'879f0867-b801-4c0e-a8d0-b0d28e065151', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134395085.jpg', N'/Images/Gallery/20150413/201504131134395085.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECB34 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'd19cae78-ba7e-476d-80b9-b89fa7e1733f', N'aa25f8b7-1525-4c31-bc98-a479013c91bf', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131951057844.jpg', N'/Images/Gallery/20150413/201504131951057844.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47901472511 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'2d3e7b95-a8a9-43c5-8473-bb0eac26d5b4', N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132012499173.jpg', N'/Images/Gallery/20150413/201504132012499173.jpg', N'暂无描述...', 0, 0, CAST(0x0000A479014D1D47 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'1c299020-dba8-45f5-bfb8-be7686fd4971', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233062679.jpg', N'/Images/Gallery/20150413/201504131233062679.jpg', N'列奥纳多·达·芬奇的敬意：列奥纳多·达·芬奇是从哪里找到画骡子与骑者的灵感的？', 0, 0, CAST(0x0000A47900CED8B1 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'047d84dc-357f-4fe7-abab-bf92c5c775b6', N'5786e811-5682-4ee1-949a-a47900db22ac', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131319054760.jpg', N'/Images/Gallery/20150413/201504131319054760.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900DB7A2F AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'90f569b2-a93a-4081-b7fa-c461e41247d1', N'a1492906-bed3-488d-aeb9-a47901512aa8', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132027586782.jpg', N'/Images/Gallery/20150413/201504132027586782.jpg', N'暂无描述...', 0, 0, CAST(0x0000A4790151463B AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'760eac5a-3172-48d4-94fb-c60397d68321', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313107597.jpg', N'/Images/Gallery/20150413/201504131313107597.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DA71 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'4d56dee5-529b-42d7-a15c-c60a9ca0773d', N'a1492906-bed3-488d-aeb9-a47901512aa8', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132027582202.jpg', N'/Images/Gallery/20150413/201504132027582202.jpg', N'暂无描述...', 0, 0, CAST(0x0000A479015145B1 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'66b1a4ce-f8f9-457d-9c2d-d0a811331552', N'f5b26ea5-d9d4-4d7f-97ce-a479014d04cc', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504132012491194.jpg', N'/Images/Gallery/20150413/201504132012491194.jpg', N'暂无描述...', 0, 0, CAST(0x0000A479014D1C58 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'46cf4b88-e819-4f9f-88ab-d14781de545c', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233021955.jpg', N'/Images/Gallery/20150413/201504131233021955.jpg', N'取下眼镜看图吧！', 0, 0, CAST(0x0000A47900CED3E9 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'504cc8e5-c95f-461f-9819-da03ab14b30e', N'08dcbbf3-ed14-400e-aba6-a47900beb1d6', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131134425115.jpg', N'/Images/Gallery/20150413/201504131134425115.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900BECEB7 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'7ac7d075-690e-4735-8d1f-da4d3c570b97', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313145371.jpg', N'/Images/Gallery/20150413/201504131313145371.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DEDF AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'4fecc9f3-ce19-48de-a64a-dab132048c34', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313132705.jpg', N'/Images/Gallery/20150413/201504131313132705.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DD67 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'bea25d9b-c254-4100-9505-dc5cff11cf86', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313136856.jpg', N'/Images/Gallery/20150413/201504131313136856.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9DDDF AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'62392d21-7f3f-47cd-8132-e4453c6ade0a', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251336507.jpg', N'/Images/Gallery/20150413/201504131251336507.jpg', N'暖风', 0, 0, CAST(0x0000A47900D3EA67 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'ab3b71a6-1661-4dee-b303-e498e767d2b0', N'5786e811-5682-4ee1-949a-a47900db22ac', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131319007913.jpg', N'/Images/Gallery/20150413/201504131319007913.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900DB74B3 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'08a3867f-5b1d-4c14-ba35-e942da4a043e', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313091269.jpg', N'/Images/Gallery/20150413/201504131313091269.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D887 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'72e2446c-ab1d-488b-b557-ea0f741c4c1e', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233038675.jpg', N'/Images/Gallery/20150413/201504131233038675.jpg', N'kitaoka变形的方格幻觉：这些正方形是不是有点变形？', 0, 0, CAST(0x0000A47900CED5E1 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'e78313e3-351a-4e85-b43c-ea7694cd0fa5', N'f08c10f2-21e2-4b81-9f32-a47900d3d431', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131251385395.jpg', N'/Images/Gallery/20150413/201504131251385395.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D3F024 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'e7727420-a241-4b15-b57f-ecada0d0b5cd', N'94fe8de6-8172-42c6-be6e-a47900d98478', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131313072889.jpg', N'/Images/Gallery/20150413/201504131313072889.jpg', N'暂无描述...', 0, 0, CAST(0x0000A47900D9D660 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'073e3500-ecb6-4f97-b4d0-f58e95aec37e', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233016633.jpg', N'/Images/Gallery/20150413/201504131233016633.jpg', N'提埃瑞图形：白长方格在第几层？', 0, 0, CAST(0x0000A47900CED348 AS DateTime))
INSERT [dbo].[Photo] ([PhotoId], [AtlasId], [PhotoName], [PhotoTags], [ThumbPath], [PhotoPath], [Remark], [Hits], [CommentNum], [CreateTime]) VALUES (N'bdb38990-645b-4870-9439-fdd0e14df3a8', N'65dfbd21-8c19-4bfd-81c4-a47900cebf7c', NULL, NULL, N'/Images/Gallery/20150413/thumb_201504131233068685.jpg', N'/Images/Gallery/20150413/201504131233068685.jpg', N'你喜欢哪张脸？选择左边的，你的喜好和广大男人们的喜好是一致的。这两张脸都是合成的，左边一张是由8个小脚女人的脸合并而成；右边这个是8个大脚女人的脸合成的。通常，小脚女人有着更为漂亮的脸蛋。', 0, 0, CAST(0x0000A47900CED963 AS DateTime))
SET IDENTITY_INSERT [dbo].[RecentActivity] ON 

INSERT [dbo].[RecentActivity] ([Id], [Title], [StartTime], [Address], [Content], [Status], [CreateTime]) VALUES (1, N'求索工作室新学期工作会议', CAST(0x0000A465014159A0 AS DateTime), N'院楼500', N'<span style="font-size:12.0pt;font-family:宋体;">院楼<span>500</span>举
行了本学期第一次全院心理委员会议。会议中，毛老师强调了心理委员的工作职责，明确指出了心委工作的重要性，要求心理委员要用心做到认真观察、严格保密、
及时反馈。学科调整后，数学系的心委也要及时融入新学院，适应新学院的工作安排。最后，工作室工作人员介绍了本学期的活动安排，希望心委能够积极参与，并
详细解答了近期的心理<span>DV</span>剧拍摄相关问题。</span>', 0, CAST(0x0000A47901531428 AS DateTime))
INSERT [dbo].[RecentActivity] ([Id], [Title], [StartTime], [Address], [Content], [Status], [CreateTime]) VALUES (2, N'求索工作室第一次全干会', CAST(0x0000A46500D21D10 AS DateTime), N'院楼201', N'<span style="font-size:12.0pt;font-family:宋体;">学院二级心理辅导站求索工作室于院楼<span>201</span>举
行了本学期第一次全干会。会议以总结过往，展望未来为主题。工作室指导老师毛老师肯定了上学期工作室开展的各项工作，并对新学期的工作提出几点要求：一
是，改进心理反馈方式，提高心理反馈效率；二是，举办心理知识沙龙，丰富心理健康知识；三是，开展室外心理团体活动，增强心理素质。</span>', 0, CAST(0x0000A47901536BE7 AS DateTime))
INSERT [dbo].[RecentActivity] ([Id], [Title], [StartTime], [Address], [Content], [Status], [CreateTime]) VALUES (3, N'求索工作室第六届换届大会', CAST(0x0000A345014159A0 AS DateTime), N'院楼500', N'6<span style="line-height:150%;font-family:宋体;font-size:12pt;">月<span>7</span>日</span><span style="line-height:150%;font-family:宋体;font-size:12pt;">晚，信息学院、软件学院二级心理辅导站求索工作室在院楼<span>500</span>举办了第七届换届大会。工作室指导老师毛丹鹃老师、工作室成员、心理委员等参加了会议。本次换届大会的主题是“新的起点，新的求索”。</span>', 0, CAST(0x0000A4790153E264 AS DateTime))
INSERT [dbo].[RecentActivity] ([Id], [Title], [StartTime], [Address], [Content], [Status], [CreateTime]) VALUES (4, N'第六届DV剧大赛', CAST(0x0000A318014159A0 AS DateTime), N'院楼500', N'<span style="line-height:150%;font-family:宋体;font-size:12pt;">信息学院、软件学院求索工作室举办的<span>DV</span>剧决赛于<span>4</span>月<span>25</span>日晚在院楼<span>500</span>顺利举行。校心理健康辅导中心金艺花老师、工作室指导老师毛丹鹃老师以及<span>13</span>级辅导员陈思老师、林晓珊老师应邀出席了本次决赛。</span>', 0, CAST(0x0000A47901542D29 AS DateTime))
INSERT [dbo].[RecentActivity] ([Id], [Title], [StartTime], [Address], [Content], [Status], [CreateTime]) VALUES (5, N'新学期心理委员会议', CAST(0x0000A2F100D21D10 AS DateTime), N'院楼500', N'<span style="font-size:16px;">&nbsp;3月14日中午，新学期第一次心理委员会议在信息（软件）学院院楼500会议室举行。本次会议由陈素婷担任主持，求索工作室指导老师毛丹鹃老师、工作室全体成员以及2011、2012、2013级各班心理委员参加了本次会议。</span><br />', 0, CAST(0x0000A47901551C9D AS DateTime))
INSERT [dbo].[RecentActivity] ([Id], [Title], [StartTime], [Address], [Content], [Status], [CreateTime]) VALUES (6, N'第七届DV剧决赛', CAST(0x0000A492014159A0 AS DateTime), N'院楼500', N'<span style="line-height:150%;font-family:宋体;font-size:12pt;">第七届DV剧大家即将开始，共有XX部作品角逐冠军，现场还有小礼品发送，期待大家的参与，DV剧欢聚之夜，有你的参与更精彩！忘了告诉你了，时间暂定哦，但是一定会有的</span>', 0, CAST(0x0000A4790157389A AS DateTime))
SET IDENTITY_INSERT [dbo].[RecentActivity] OFF
SET IDENTITY_INSERT [dbo].[Tag] ON 

INSERT [dbo].[Tag] ([TagId], [TagName], [TagEnglish], [TagDescription], [Belong], [TagSum], [CreateTime]) VALUES (1, N'Tag1', N'tag', NULL, 2, 0, CAST(0x0000A6BC011FF5B9 AS DateTime))
INSERT [dbo].[Tag] ([TagId], [TagName], [TagEnglish], [TagDescription], [Belong], [TagSum], [CreateTime]) VALUES (2, N'Tag2', N'tag2', NULL, 0, 0, CAST(0x0000A6BC012008E8 AS DateTime))
SET IDENTITY_INSERT [dbo].[Tag] OFF
SET IDENTITY_INSERT [dbo].[User] ON 

INSERT [dbo].[User] ([UserId], [UserName], [Password], [RealName], [StuNumber], [Identification], [Gender], [Phone], [Email], [PhotoUrl], [About], [PersonalPage], [State], [Roles]) VALUES (1, N'Admin', N'e10adc3949ba59abbe56e057f20f883e', N'廖桂发', N'123456789012', N'管理员', 0, N'12345678954', N'123456@gmail.com', N'201131000813_635572629326975281.jpg', N'你好，我是管理员', NULL, 1, N'Admin')
SET IDENTITY_INSERT [dbo].[User] OFF
SET IDENTITY_INSERT [dbo].[Video] ON 

INSERT [dbo].[Video] ([VideoId], [VideoName], [ThumbPath], [VideoPath], [Remark], [Hits], [CommentNum], [CreateTime], [Category], [ComesFrom], [IsLocal], [Recommend]) VALUES (1, N'回到最初的地方', N'/Images/Videos/20150413/201504131112153669.jpg', N'http://player.youku.com/player.php/sid/XNjkxOTYwMzg0/v.swf', N'第六届DV剧大赛一等奖作品：华农13级软工四班心理剧--回到最初的地方', 5, 0, CAST(0x0000A47900B8A404 AS DateTime), N'心理DV剧', N'优酷', 0, 0)
INSERT [dbo].[Video] ([VideoId], [VideoName], [ThumbPath], [VideoPath], [Remark], [Hits], [CommentNum], [CreateTime], [Category], [ComesFrom], [IsLocal], [Recommend]) VALUES (2, N'take it back', N'/Images/Videos/20150413/201504131118384131.jpg', N'http://player.youku.com/player.php/sid/XNjkyMjgzODA0/v.swf', N'第六届DV剧大赛二等奖作品：13软工2班', 6, 0, CAST(0x0000A47900BA64E5 AS DateTime), N'心理DV剧', N'优酷', 0, 0)
INSERT [dbo].[Video] ([VideoId], [VideoName], [ThumbPath], [VideoPath], [Remark], [Hits], [CommentNum], [CreateTime], [Category], [ComesFrom], [IsLocal], [Recommend]) VALUES (3, N'回到最开始的地方', N'/Images/Videos/20150413/201504131121529298.jpg', N'http://player.youku.com/player.php/sid/XNjk0NjgzMDA4/v.swf', N'第六届DV剧大赛三等奖作品：12软件R8班', 8, 0, CAST(0x0000A47900BB48D9 AS DateTime), N'心理DV剧', N'优酷', 0, 0)
INSERT [dbo].[Video] ([VideoId], [VideoName], [ThumbPath], [VideoPath], [Remark], [Hits], [CommentNum], [CreateTime], [Category], [ComesFrom], [IsLocal], [Recommend]) VALUES (4, N'ON MY WAY', N'/Images/Videos/20150413/201504131125398663.jpg', N'http://player.youku.com/player.php/sid/XNjk0NjA0OTA4/v.swf', N'第六届DV剧大赛：13信管3班', 7, 0, CAST(0x0000A47900BC52C8 AS DateTime), N'心理DV剧', N'优酷', 0, 0)
SET IDENTITY_INSERT [dbo].[Video] OFF
ALTER TABLE [dbo].[Book] ADD  CONSTRAINT [DF_Book_Already]  DEFAULT ((0)) FOR [Already]
GO
ALTER TABLE [dbo].[Book] ADD  CONSTRAINT [DF_Book_Wish]  DEFAULT ((0)) FOR [Wish]
GO
ALTER TABLE [dbo].[Book] ADD  CONSTRAINT [DF_Book_Reading]  DEFAULT ((0)) FOR [Reading]
GO
ALTER TABLE [dbo].[LoginLog] ADD  CONSTRAINT [DF__LoginLog__LoginT__7B4643B2]  DEFAULT (getdate()) FOR [LoginTime]
GO
ALTER TABLE [dbo].[News] ADD  CONSTRAINT [DF_News_ViewTimes]  DEFAULT ((0)) FOR [ViewTimes]
GO
ALTER TABLE [dbo].[News] ADD  CONSTRAINT [DF_News_CommentNum]  DEFAULT ((0)) FOR [CommentNum]
GO
ALTER TABLE [dbo].[Photo] ADD  CONSTRAINT [DF_Photo_Remark]  DEFAULT (N'暂无描述...') FOR [Remark]
GO
ALTER TABLE [dbo].[Photo] ADD  CONSTRAINT [DF_Photo_Hits]  DEFAULT ((0)) FOR [Hits]
GO
ALTER TABLE [dbo].[Photo] ADD  CONSTRAINT [DF_Photo_CommentNum]  DEFAULT ((0)) FOR [CommentNum]
GO
ALTER TABLE [dbo].[Tag] ADD  CONSTRAINT [DF_Tag_Belong]  DEFAULT ((0)) FOR [Belong]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_UserName]  DEFAULT (N'佚名') FOR [UserName]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_Identification]  DEFAULT (N'路人') FOR [Identification]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_Sex]  DEFAULT ((0)) FOR [Gender]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_Phone]  DEFAULT ('------------') FOR [Phone]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_Email]  DEFAULT ('------------') FOR [Email]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_PhotoUrl]  DEFAULT (N'no-image.png') FOR [PhotoUrl]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_About]  DEFAULT (N'这人太懒了，什么都没留下……') FOR [About]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_PersonalPage]  DEFAULT ('华农的某个角落') FOR [PersonalPage]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_State]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_Roles]  DEFAULT (N'Normal') FOR [Roles]
GO
ALTER TABLE [dbo].[ArticleComment]  WITH CHECK ADD  CONSTRAINT [FK_ArticleComment_Article] FOREIGN KEY([ArticleId])
REFERENCES [dbo].[Article] ([ArticleId])
GO
ALTER TABLE [dbo].[ArticleComment] CHECK CONSTRAINT [FK_ArticleComment_Article]
GO
ALTER TABLE [dbo].[BookComment]  WITH CHECK ADD  CONSTRAINT [FK_BookComment_Book] FOREIGN KEY([BookId])
REFERENCES [dbo].[Book] ([BookId])
GO
ALTER TABLE [dbo].[BookComment] CHECK CONSTRAINT [FK_BookComment_Book]
GO
ALTER TABLE [dbo].[BookComment]  WITH CHECK ADD  CONSTRAINT [FK_BookComment_Book1] FOREIGN KEY([BookId])
REFERENCES [dbo].[Book] ([BookId])
GO
ALTER TABLE [dbo].[BookComment] CHECK CONSTRAINT [FK_BookComment_Book1]
GO
ALTER TABLE [dbo].[FbDocument]  WITH CHECK ADD  CONSTRAINT [FK_FbDocument_Feedback] FOREIGN KEY([FeedbackId])
REFERENCES [dbo].[Feedback] ([FeedbackId])
GO
ALTER TABLE [dbo].[FbDocument] CHECK CONSTRAINT [FK_FbDocument_Feedback]
GO
ALTER TABLE [dbo].[FbDocument]  WITH CHECK ADD  CONSTRAINT [FK_FbDocument_User] FOREIGN KEY([UploaderId])
REFERENCES [dbo].[User] ([UserId])
GO
ALTER TABLE [dbo].[FbDocument] CHECK CONSTRAINT [FK_FbDocument_User]
GO
ALTER TABLE [dbo].[MyMessage]  WITH CHECK ADD  CONSTRAINT [FK_MyMessage_Message] FOREIGN KEY([MId])
REFERENCES [dbo].[Message] ([MId])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MyMessage] CHECK CONSTRAINT [FK_MyMessage_Message]
GO
ALTER TABLE [dbo].[MyMessage]  WITH CHECK ADD  CONSTRAINT [FK_MyMessage_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[User] ([UserId])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MyMessage] CHECK CONSTRAINT [FK_MyMessage_User]
GO
ALTER TABLE [dbo].[NewsComment]  WITH CHECK ADD  CONSTRAINT [FK_NewsComment_News] FOREIGN KEY([NewsId])
REFERENCES [dbo].[News] ([NewsId])
GO
ALTER TABLE [dbo].[NewsComment] CHECK CONSTRAINT [FK_NewsComment_News]
GO
ALTER TABLE [dbo].[VideoComment]  WITH CHECK ADD  CONSTRAINT [FK_VideoComment_Video] FOREIGN KEY([VideoId])
REFERENCES [dbo].[Video] ([VideoId])
GO
ALTER TABLE [dbo].[VideoComment] CHECK CONSTRAINT [FK_VideoComment_Video]
GO
USE [master]
GO
ALTER DATABASE [QSDB] SET  READ_WRITE 
GO
