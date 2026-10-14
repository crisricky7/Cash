namespace Cash.Domain.Entities;

public class StoryTip
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Tag { get; set; } = "TIP OFICIAL CASH • 5 SEG";
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string ActionTip { get; set; } = string.Empty;
    public string ThemeKey { get; set; } = "salvia";
    public string CreatedByDeveloperEmail { get; set; } = "admin@cashapp.com";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
