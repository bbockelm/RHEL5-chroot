
Name: chroot-tool
Group: Applications/System
Version: 0.2
Release: 1%{?dist}
Summary: A tool for creating and manipulating chroots

License: Apache 2.0

Source0: chroot-tool
Source1: yum.conf
Source2: tool.cfg

Requires: yum
Requires: rpm

BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
A small, simple tool for creating and manipulating chroots

%prep
%setup -q -c -T

cp %{SOURCE0} .
cp %{SOURCE1} .
cp %{SOURCE2} .

%install
rm -rf $RPM_BUILD_ROOT

mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/%{name}
mkdir -p $RPM_BUILD_ROOT%{_sbindir}

install -m 0700 %{name} $RPM_BUILD_ROOT%{_sbindir}/%{name}
install -m 0644 tool.cfg $RPM_BUILD_ROOT%{_sysconfdir}/%{name}/tool.cfg
install -m 0644 yum.conf $RPM_BUILD_ROOT%{_sysconfdir}/%{name}/yum.conf

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{_sbindir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/tool.cfg
%config(noreplace) %{_sysconfdir}/%{name}/yum.conf

%changelog
* Thu Feb 09 2012 Brian Bockelman <bbockelm@cse.unl.edu> - 0.2-1
- Added line to secure chroot.

* Thu Feb 09 2012 Brian Bockelman <bbockelm@cse.unl.edu> - 0.1-1
- Initial release of chroot-tool.


