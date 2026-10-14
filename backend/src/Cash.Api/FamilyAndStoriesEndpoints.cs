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
            {
                return Results.Problem(
                    "Acceso denegado: Solo el Administrador/Desarrollador de Cash puede publicar historias diarias.",
                    statusCode: 403);
            }

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
            {
                return Results.BadRequest(new
                {
                    message = $"Has alcanzado el límite de {maxAllowed} usuario(s) de tu plan actual ({req.SubscriptionTier})."
                });
            }

            var invitation = new HouseholdInvitation
            {
                InvitedName = req.InvitedName.Trim(),
                InvitedEmail = req.InvitedEmail.Trim().ToLowerInvariant(),
                Status = "Pending"
            };
            _invitations.Add(invitation);

            return Results.Ok(new
            {
                invitation.Id,
                invitation.InvitedName,
                invitation.InvitedEmail,
                invitation.InvitationToken,
                invitation.Status,
                acceptUrl = $"https://crisricky7.github.io/Cash/?acceptInvite={invitation.InvitationToken}",
                message = $"Invitación enviada por correo a {invitation.InvitedEmail}."
            });
        });

        api.MapPost("/family/invitations/{token}/accept", (string token) =>
        {
            var inv = _invitations.FirstOrDefault(i => i.InvitationToken == token);
            if (inv is null) return Results.NotFound(new { message = "Invitación no encontrada." });

            inv.Status = "Accepted";
            inv.AcceptedAt = DateTime.UtcNow;

            return Results.Ok(new
            {
                inv.InvitedName,
                inv.InvitedEmail,
                inv.Status,
                familyModeActivated = true,
                message = $"{inv.InvitedName} se ha unido a la familia automáticamente."
            });
        });
    }
}

public record CreateStoryRequest(string Title, string Body, string ActionTip, string ThemeKey = "salvia");
public record SendInvitationRequest(string InvitedName, string InvitedEmail, string SubscriptionTier, int CurrentActiveMembers);
