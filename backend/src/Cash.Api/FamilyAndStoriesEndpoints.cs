using System.Security.Claims;
using Cash.Domain.Entities;

namespace Cash.Api;

public static class FamilyAndStoriesEndpoints
{
    private static readonly List<StoryTip> _globalStories =
    [
        new StoryTip
        {
            Tag = "TIP OFICIAL CASH • 5 SEG",
            Title = "La Regla de las 24 Horas",
            Body = "Antes de hacer una compra no planificada mayor a $30, espera 24 horas. El 70% de las veces el impulso desaparece.",
            ActionTip = "Aplica esta pausa hoy antes de comprar por impulso."
        }
    ];

    private static readonly List<HouseholdInvitation> _invitations = [];

    public static void MapFamilyAndStoriesEndpoints(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("/api");

        api.MapGet("/stories", () => Results.Ok(_globalStories.OrderByDescending(s => s.CreatedAt)));

        api.MapPost("/stories", (CreateStoryRequest req, ClaimsPrincipal user) =>
        {
            var role = user.FindFirstValue(ClaimTypes.Role) ?? "";
            if (!string.Equals(role, "SuperAdmin", StringComparison.OrdinalIgnoreCase))
                return Results.Problem("Solo el Administrador/Desarrollador puede publicar historias.", statusCode: 403);

            var story = new StoryTip
            {
                Title = req.Title.Trim(),
                Body = req.Body.Trim(),
                ActionTip = req.ActionTip.Trim(),
                ThemeKey = req.ThemeKey
            };
            _globalStories.Add(story);
            return Results.Created($"/api/stories/{story.Id}", story);
        }).RequireAuthorization();

        api.MapPost("/family/invitations", (SendInvitationRequest req) =>
        {
            var maxAllowed = req.SubscriptionTier switch
            {
                "familiar_plus" => 7,
                "familiar" => 4,
                _ => 1
            };

            if (req.CurrentActiveMembers >= maxAllowed)
                return Results.BadRequest(new { message = $"Límite de {maxAllowed} usuario(s) alcanzado." });

            var invitation = new HouseholdInvitation
            {
                InvitedName = req.InvitedName.Trim(),
                InvitedEmail = req.InvitedEmail.Trim().ToLowerInvariant(),
                Status = "Pending"
            };
            _invitations.Add(invitation);

            return Results.Ok(invitation);
        });

        api.MapPost("/family/invitations/{token}/accept", (string token) =>
        {
            var inv = _invitations.FirstOrDefault(i => i.InvitationToken == token);
            if (inv is null) return Results.NotFound();
            inv.Status = "Accepted";
            inv.AcceptedAt = DateTime.UtcNow;
            return Results.Ok(inv);
        });
    }
}

public record CreateStoryRequest(string Title, string Body, string ActionTip, string ThemeKey = "salvia");
public record SendInvitationRequest(string InvitedName, string InvitedEmail, string SubscriptionTier, int CurrentActiveMembers);
