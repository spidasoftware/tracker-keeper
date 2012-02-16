var tracker;

$(document).ready(function() {
  tracker = new TrackerKeeper();
  $(".story a.name").click(function() {
    tracker.loadStory(
      $(this).parents(".story").attr("data-project-id"),
      $(this).parents(".story").attr("data-story-id")
    );
    return false;
  });
  $(".story .action").click(function() {
    tracker.updateStatus(
      $(this).parents(".story").attr("data-project-id"),
      $(this).parents(".story").attr("data-story-id"),
      $(this).attr('data-action')
    );
    return false;
  });
});

var TrackerKeeper = function() {
  this.loadStory = (function(projectId, storyId) {
    var description = $("div [data-story-id="+storyId+"] .description")
    if (description.size() > 0) {
      if (description.html() == "") {
        $.ajax({
          type:'GET',
          data:'storyId='+storyId+'&projectId='+projectId,
          url:'/load',
          success:function(data) {
            description.html(data).show();
          }
        });
      } else {
        description.toggle();
      }
    }
  });

  this.updateStatus = (function(projectId, storyId, action) {
    var project = $("div [data-story-id="+storyId+"]")
    if (project.size() > 0) {
      $.ajax({
        type:'POST',
        data:'storyId='+storyId+'&projectId='+projectId+'&action='+action,
        url:'/update',
        success:function(data) {
          project.children(".actions").html(data);
        }
      });
    }
  });
}