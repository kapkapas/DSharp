unit DSharp.PresentationModel.ScreenIntf;

interface

uses
  DSharp.PresentationModel.NotifyPropertyChangedExIntf;

type
  ///	<summary>
  ///	  Denotes an instance which implements <see cref="IHaveDisplayName" />,
  ///	  <see cref="IActivate" />, <see cref="IDeactivate" />,
  ///	  <see cref="IGuardClose" />and <see cref="INotifyPropertyChangedEx" />
  ///	</summary>
  IScreen = interface(INotifyPropertyChangedEx)
    ['{F9296F6C-AF54-4049-8D84-6C187D081710}']
  end;

implementation

end.